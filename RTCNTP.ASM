; Simple NTP client for DS1302 RTC board
; Copyright (c) 2018 by Marco Maccaferri
;
; Compile on CP/M with:
;
;   C:ASM RTCNTP
;   C:LOAD RTCNTP
;
; Invoke with:
;
;   RTCNTP [/N] [/Sntp.server]
;
;   /N - Don't write to RTC
;   /S - Specify NTP server to use

TIMEOUT     EQU   0
OK          EQU   1
ERROR       EQU   2
UNKNOWN     EQU   0FFH

AUXST       EQU   0E956H
AUXRB       EQU   0E966H
AUXWB       EQU   0E9E0H

RTCPORT     EQU   0C0H

WRMASK      EQU   10000000B
CLKMASK     EQU   01000000B
RDMASK      EQU   00100000B
CSMASK      EQU   00010000B

CR          EQU   13
LF          EQU   10

BDOS        EQU   0005H

UPDATERTC   EQU   00000001B

DEBUG       EQU   0         ; set to 1 to enable debug mode

            ORG   0100H

START:
            ; parse command line

            LXI   H,80H
            MOV   C,M

L1          CALL  GETNEXT
            JZ    RUN
            CPI   '/'
            JNZ   L1

            CALL  GETNEXT
            JZ    RUN
            CPI   'N'
            JZ    L2
            CPI   'S'
            JZ    L3
            JMP   L1

L2          LDA   FLAGS     ; don't write to RTC
            XRI   UPDATERTC
            STA   FLAGS
            JMP   L1
            
L3          LXI   D,SERVER  ; NTP server

L4          CALL  GETNEXT   ; skip initial spaces
            JZ    RUN
            CPI   ' '
            JZ    L4

L5          STAX  D
            INX   D
            CALL  GETNEXT   ; copy string up to next space
            JZ    L6
            CPI   ' '
            JZ    L6
            JMP   L5

L6          XRA   A         ; zero-terminate string
            STAX  D
            JMP   L1

RUN:

            ; query the ntp server

L7          CALL  AUXRBT        ; clear incoming buffer
            JNZ   L7

            LXI   H,AT          ; test ESP-01 presence
            CALL  AUXWS
            CALL  GETRESPONSE
            CPI   OK
            JNZ   PERR1

            LXI   H,ATE0        ; disable echo
            CALL  AUXWS
            CALL  GETRESPONSE
            CPI   OK
            JNZ   PERR1
            
            LXI   H,CIPMUX      ; set single connection
            CALL  AUXWS
            CALL  GETRESPONSE
            CPI   OK
            JNZ   PERR1

            CALL  UDPOPEN       ; open UDP connection
            CPI   OK
            JNZ   PERR1
            
L9          XRA   A             ; prepare ntp query
            MVI   C,48
            LXI   H,UDPBUF
L13         MOV   M,A
            INX   H
            DCR   C
            JNZ   L13

            MVI   A,1BH
            STA   UDPBUF

            CALL  UDPSEND       ; send packet
            CPI   OK
            JNZ   PERR1

            MVI   A,60          ; ~30 sec. timeout
            STA   RETRYCNT

L16         CALL  UDPGET
            CPI   0
            JNZ   L15

            MVI   C,06H         ; poll console
            MVI   E,0FFH
            CALL  0005H
            CPI   03H           ; CTRL-C exit
            JZ    USREXIT

            LDA   RETRYCNT
            DCR   A
            STA   RETRYCNT
            JNZ   L16

            LXI   D,ERR2
            MVI   C,09H
            CALL  BDOS

            JMP   L9

L15         CALL  UDPCLOSE

            LDA   UDPBUF+40     ; update timestamp from packet
            STA   TIMESTAMP+0
            LDA   UDPBUF+41
            STA   TIMESTAMP+1
            LDA   UDPBUF+42
            STA   TIMESTAMP+2
            LDA   UDPBUF+43
            STA   TIMESTAMP+3

            CALL  LOCALTIME     ; compute local time
            CALL  TOSTRING

            LDA   FLAGS         ; update RTC
            ANI   UPDATERTC
            JZ    L19
            CALL  RTCWRITE

L19         LXI   D,DATETIME    ; display date and time string
            MVI   C,09H
            CALL  BDOS

            RET

PERR1:      LXI   D,ERR1
            MVI   C,09H
            CALL  BDOS
            RET

USREXIT:
            LXI   D,ERR3
            MVI   C,09H
            CALL  BDOS
            CALL  UDPCLOSE
            RET

GETNEXT:
            MOV   A,C
            ORA   A
            RZ
            DCR   C
            INX   H
            MOV   A,M
            ORA   A
            RET

; Date / time functions

LOCALTIME:
            LXI   H,TIMEDIFF      
            CALL  ADD32
            ; Fall through

GMTIME:
            LXI   H,OFFSET
            CALL  SUB32

CALCYEAR:
            LDA   YEAR
            ANI   03H
            JZ    LEAP

NOLEAP:
            LXI   H,SECSYEAR
            CALL  SUB32
            JNC   L20

            LXI   H,SECSYEAR
            CALL  ADD32
            CALL  ADDLEAP
            JMP   CALCMONTH

LEAP:
            LXI   H,SECSLYEAR
            CALL  SUB32
            JNC   L20

            LXI   H,SECSLYEAR
            CALL  ADD32
            CALL  ADDLEAP
            JMP   CALCMONTH

L20:
            LDA   WDAY
            MOV   C,A
            INR   C

            LDA   YEAR
            ANI   03H
            JNZ   L21
            INR   C

L21:        MOV   A,C
            CPI   8
            JC    L22
            SUI   7
L22:        STA   WDAY

            LDA   YEAR
            INR   A
            STA   YEAR
            JMP   CALCYEAR

CALCMONTH:
            LDA   MONTH
            ADD   A
            ADD   A
            LXI   H,SECSMONTH-4
            ADD   L
            MOV   L,A
            MOV   A,H
            ACI   000H
            MOV   H,A

            CALL  SUB32
            JNC   L23

            DCX   H
            DCX   H
            DCX   H
            CALL  ADD32
            CALL  SUBLEAP
            JMP   CALCDAY

L23:
            LDA   MONTH
            LXI   H,WDMONTH-1
            ADD   L
            MOV   L,A
            MOV   A,H
            ACI   000H
            MOV   H,A
            
            MOV   C,M
            LDA   WDAY
            ADD   C
            CPI   8
            JC    L24
            SUI   7
L24:        STA   WDAY

            LDA   MONTH
            INR   A
            STA   MONTH

            JMP   CALCMONTH

CALCDAY:
            LXI   H,SECSDAY
            CALL  SUB32
            JNC   L25

            LXI   H,SECSDAY
            CALL  ADD32
            JMP   CALCHOUR

L25:
            LDA   DAY
            INR   A
            STA   DAY

            LDA   WDAY
            INR   A
            CPI   8
            JC    L26
            SUI   7
L26:        STA   WDAY

            JMP   CALCDAY

CALCHOUR:
            LXI   H,SECSHOUR
            CALL  SUB32
            JNC   L27

            LXI   H,SECSHOUR
            CALL  ADD32
            JMP   CALCMIN

L27:
            LDA   HOURS
            INR   A
            STA   HOURS
            JMP   CALCHOUR

CALCMIN:
            LXI   H,SECSMIN
            CALL  SUB32
            JNC   L28

            LXI   H,SECSMIN
            CALL  ADD32
            JMP   CALCDONE

L28:
            LDA   MINUTES
            INR   A
            STA   MINUTES
            JMP   CALCMIN

CALCDONE:
            LDA   TIMESTAMP+3
            STA   SECONDS
            RET

SUB32:
            MOV   B,M
            INX   H
            MOV   C,M
            INX   H
            MOV   D,M
            INX   H
            MOV   E,M

            LDA   TIMESTAMP+3
            SUB   E
            STA   TIMESTAMP+3

            LDA   TIMESTAMP+2
            SBB   D
            STA   TIMESTAMP+2

            LDA   TIMESTAMP+1
            SBB   C
            STA   TIMESTAMP+1

            LDA   TIMESTAMP+0
            SBB   B
            STA   TIMESTAMP+0

            RET

ADD32:
            MOV   B,M
            INX   H
            MOV   C,M
            INX   H
            MOV   D,M
            INX   H
            MOV   E,M

            LDA   TIMESTAMP+3
            ADD   E
            STA   TIMESTAMP+3

            LDA   TIMESTAMP+2
            ADC   D
            STA   TIMESTAMP+2

            LDA   TIMESTAMP+1
            ADC   C
            STA   TIMESTAMP+1

            LDA   TIMESTAMP+0
            ADC   B
            STA   TIMESTAMP+0

            RET

ADDLEAP:
            LDA   YEAR
            ANI   03H
            RNZ

            LDA   SECSMONTH+4+3
            ADI   080H
            STA   SECSMONTH+4+3

            LDA   SECSMONTH+4+2
            ACI   051H
            STA   SECSMONTH+4+2

            LDA   SECSMONTH+4+1
            ACI   001H
            STA   SECSMONTH+4+1

            LDA   SECSMONTH+4+0
            ACI   000H
            STA   SECSMONTH+4+0
            
            LDA   WDMONTH+1
            INR   A
            STA   WDMONTH+1

            RET

SUBLEAP:
            LDA   YEAR
            ANI   03H
            RNZ

            LDA   SECSMONTH+4+3
            SUI   080H
            STA   SECSMONTH+4+3

            LDA   SECSMONTH+4+2
            SBI   051H
            STA   SECSMONTH+4+2

            LDA   SECSMONTH+4+1
            SBI   001H
            STA   SECSMONTH+4+1

            LDA   SECSMONTH+4+0
            SBI   000H
            STA   SECSMONTH+4+0
            
            LDA   WDMONTH+1
            DCR   A
            STA   WDMONTH+1

            RET

OFFSET:     DB    0BCH, 017H, 0C2H, 000H  ; 01-01-2000 00:00:00

SECSYEAR    DB    001H, 0E1H, 033H, 080H
SECSLYEAR   DB    001H, 0E2H, 085H, 000H

SECSMONTH:  DB    000H, 028H, 0DEH, 080H  ; JAN
            DB    000H, 024H, 0EAH, 000H  ; FEB
            DB    000H, 028H, 0DEH, 080H  ; MAR
            DB    000H, 027H, 08DH, 000H  ; APR
            DB    000H, 028H, 0DEH, 080H  ; MAJ
            DB    000H, 027H, 08DH, 000H  ; JUN
            DB    000H, 028H, 0DEH, 080H  ; JUL
            DB    000H, 028H, 0DEH, 080H  ; AUG
            DB    000H, 027H, 08DH, 000H  ; SEP
            DB    000H, 028H, 0DEH, 080H  ; OCT
            DB    000H, 027H, 08DH, 000H  ; NOV
            DB    000H, 028H, 0DEH, 080H  ; DEC

SECSDAY:    DB    000H, 001H, 051H, 080H

SECSHOUR:   DB    000H, 000H, 00EH, 010H

SECSMIN:    DB    000H, 000H, 000H, 03CH

WDMONTH:    DB    3, 0, 3, 2, 3, 2, 3, 3, 2, 3, 2, 3

; ESP-01 routines

UDPOPEN:
            LXI   H,CIPSTART    ; start UDP connection
            CALL  AUXWS
            PUSH  H
            LXI   H,SERVER
            CALL  AUXWS
            POP   H
            INX   H
            CALL  AUXWS
L10         CALL  GETRESPONSE
            CPI   UNKNOWN
            JZ    L10
            RET

UDPSEND:
            LXI   H,CIPSEND
            CALL  AUXWS
UDPSEND1    CALL  GETRESPONSE
            CPI   UNKNOWN
            JZ    UDPSEND1
            CPI   OK
            RNZ

UDPSEND2    CALL  AUXRBT
            JZ    UDPSEND2
            CPI   '>'
            JNZ   UDPSEND2
            
            CALL  AUXRBT

            LXI   H,UDPBUF      ; send packet
            MVI   C,48
UDPSEND3    PUSH  B
            PUSH  H
            MOV   C,M
            CALL  AUXWB
            POP   H
            POP   B
            INX   H
            DCR   C
            JNZ   UDPSEND3

UDPSEND4    CALL  GETRESPONSE
            CPI   TIMEOUT
            RZ
            
            LXI   H,BUF
            LXI   D,STRSENDOK
            CALL  STRCMP
            JNZ   UDPSEND4
            
            MVI   A,OK
            RET

UDPGET:
            XRA   A
            STA   UDPCNT

UDPGET1     CALL  AUXRBT
            JZ    UDPGET9
            CPI   '+'
            JNZ   UDPGET1
            CALL  AUXRBT
            CPI   'I'
            JNZ   UDPGET9
            CALL  AUXRBT
            CPI   'P'
            JNZ   UDPGET9
            CALL  AUXRBT
            CPI   'D'
            JNZ   UDPGET9
            CALL  AUXRBT
            CPI   2CH
            JNZ   UDPGET9

            XRA   A
            STA   COUNT

UDPGET2     CALL  AUXRBT
            JZ    UDPGET9
            CPI   ':'
            JZ    UDPGET3

            CPI   30H
            JC    UDPGET2
            CPI   3AH
            JNC   UDPGET2
            
            SUI   30H
            MOV   B,A
            LDA   COUNT
            ADD   A
            MOV   C,A
            ADD   A
            ADD   A
            ADD   C
            ADD   B
            STA   COUNT
            JMP   UDPGET2

UDPGET3     LXI   H,UDPBUF
            SHLD  BUFPTR
            LDA   COUNT

UDPGET5     CPI   0
            JZ    UDPGET9

            CALL  AUXRBT
            JNZ   UDPGET4
            CALL  AUXRBT
            JNZ   UDPGET4
            CALL  AUXRBT
            JZ    UDPGET9

UDPGET4     LHLD  BUFPTR
            MOV   M,A
            INX   H
            SHLD  BUFPTR
            LDA   UDPCNT
            INR   A
            STA   UDPCNT
            LDA   COUNT
            DCR   A
            STA   COUNT
            JMP   UDPGET5

UDPGET9     LDA   UDPCNT
            RET

UDPCLOSE:
            LXI   H,CIPCLOSE    ; close connection
            CALL  AUXWS
UDPCLOSE1:  CALL  GETRESPONSE
            CPI   UNKNOWN
            JZ    UDPCLOSE1
            RET

GETRESPONSE:
            LXI   H,BUF
            SHLD  BUFPTR
            MVI   A,0
            MOV   M,A

G2:         CALL  AUXRBT
            JNZ   G1
            CALL  AUXRBT
            JNZ   G1
            CALL  AUXRBT
            JNZ   G1
          
            MVI   A,TIMEOUT   ; timeout
            RET
        
G1:         CPI   LF          ; end of line
            JZ    G3
            CPI   32          ; Skip if < 32
            JC    G2
            CPI   128         ; Skip if >=128
            JNC   G2
        
            LHLD  BUFPTR      ; store character in buffer
            MOV   M,A
            INX   H
            SHLD  BUFPTR
            JMP   G2

G3:         MVI   A,0
            LHLD  BUFPTR
            MOV   M,A

            LDA   BUF
            ORA   A           ; empty response, loop
            JZ    GETRESPONSE

            CPI   'A'         ; echo of our command, loop
            JNZ   G6
            LDA   BUF+1
            CPI   'T'
            JZ    GETRESPONSE

G6          LXI   H,BUF       ; compare with OK
            LXI   D,STROK
            CALL  STRCMP
            JNZ   G4

            MVI   A,OK
            RET

G4:         LXI     H,BUF       ; compare with ERROR
            LXI     D,STRERROR
            CALL    STRCMP
            JNZ     G5
          
            MVI     A,ERROR
            RET

G5:         MVI     A,UNKNOWN   ; Unknown response
            RET

AUXWS:
            MOV     A,M
            ORA     A
            RZ
            PUSH    H

IF DEBUG            
            PUSH    PSW
            MVI     C,02H
            MOV     E,A
            CALL    BDOS
            POP     PSW
ENDIF

            MOV     C,A
            CALL    AUXWB

            POP     H
            INX     H
            JMP     AUXWS

AUXRBT:
            LXI     B,25598     ; 500 ms. timeout
AUXRBT1     DCX     B           ; calculated for 7.3728 MHz
            MOV     A,B
            ORA     C
            RZ                  ; Z=timeout
            PUSH    B
            CALL    AUXST
            POP     B
            CPI     0
            JZ      AUXRBT1
            CALL    AUXRB

IF DEBUG            
            PUSH    PSW
            MVI     C,02H
            MOV     E,A
            CALL    BDOS
            POP     PSW
ENDIF

            ORA     A
            RNZ                 ; NZ=byte received
            CPI     0FFH        ; force NZ
            RET

; DS1302 Realtime Clock routines

RTCWRITE:
            DI

            ; enable write to clock data

            MVI     A,WRMASK + RDMASK + CSMASK
            OUT     RTCPORT
            CALL    BITDELAY
            CALL    BITDELAY
            
            MVI     C,8EH
            CALL    DSWB
            MVI     C,00H
            CALL    DSWB

            MVI     A,WRMASK + RDMASK
            OUT     RTCPORT
            CALL    BITDELAY
            CALL    BITDELAY
            
            ; burst write clock data

            MVI     A,WRMASK + RDMASK + CSMASK
            OUT     RTCPORT
            CALL    BITDELAY
            CALL    BITDELAY
            
            MVI     C,0BEH
            CALL    DSWB

            LDA     SECONDS
            CALL    TOBCD
            MOV     C,A     ; seconds
            CALL    DSWB

            LDA     MINUTES
            CALL    TOBCD
            MOV     C,A     ; minutes
            CALL    DSWB

            LDA     HOURS
            CALL    TOBCD
            MOV     C,A     ; hours
            CALL    DSWB

            LDA     DAY
            CALL    TOBCD
            MOV     C,A     ; day
            CALL    DSWB

            LDA     MONTH
            CALL    TOBCD
            MOV     C,A     ; month
            CALL    DSWB

            LDA     WDAY
            CALL    TOBCD
            MOV     C,A     ; weekday
            CALL    DSWB

            LDA     YEAR
            CALL    TOBCD
            MOV     C,A     ; year
            CALL    DSWB

            MVI     C,80H   ; write protect
            CALL    DSWB

            MVI     A,WRMASK + RDMASK
            OUT     RTCPORT
            CALL    BITDELAY
            CALL    BITDELAY

            EI
            RET

DSWB:
            XRA     A

DSWB1       PUSH    PSW
            MOV     A,C
            RAR
            MOV     C,A
            JNC     DSWB2
            MVI     A,CSMASK + WRMASK
            OUT     RTCPORT
            CALL    BITDELAY
            MVI     A,CSMASK + CLKMASK + WRMASK
            OUT     RTCPORT
            JMP     DSWB3

DSWB2       MVI     A,CSMASK
            OUT     RTCPORT
            CALL    BITDELAY
            MVI     A,CSMASK + CLKMASK
            OUT     RTCPORT

DSWB3       CALL    BITDELAY
            POP     PSW
            INR     A
            CPI     08H
            JNZ     DSWB1
            RET

DSRB:
            XRA     A
            MVI     C,00H
            MVI     B,01H

DSRB1       PUSH    PSW

            MVI     A,CSMASK + RDMASK
            OUT     RTCPORT
            CALL    BITDELAY

            IN      RTCPORT
            RAR
            MOV     A,C
            RAR
            MOV     C,A

            MVI     A,CSMASK + CLKMASK + RDMASK
            OUT     RTCPORT
            CALL    BITDELAY

            POP     PSW
            INR     A
            CPI     08H
            JNZ     DSRB1
            RET

BITDELAY:
            PUSH    PSW
            MVI     A,07H

BITDELAY1   DCR     A
            JNZ     BITDELAY1

            NOP
            NOP
            POP     PSW
            RET

; Misc.

TOSTRING:
            LDA   YEAR
            CALL  TODEC
            MOV   A,D
            STA   DATETIME+13+00
            MOV   A,E
            STA   DATETIME+13+01
            
            LXI   H,MONTHS-3
            LDA   MONTH
            MOV   C,A
            ADD   C
            ADD   C
            ADD   L
            MOV   L,A
            MOV   A,H
            ACI   000H
            MOV   H,A

            MOV   A,M
            STA   DATETIME+07+00
            INX   H
            MOV   A,M
            STA   DATETIME+07+01
            INX   H
            MOV   A,M
            STA   DATETIME+07+02

            LDA   DAY
            CALL  TODEC
            MOV   A,D
            STA   DATETIME+04+00
            MOV   A,E
            STA   DATETIME+04+01
            
            LXI   H,WEEKDAYS-3
            LDA   WDAY
            MOV   C,A
            ADD   C
            ADD   C
            ADD   L
            MOV   L,A
            MOV   A,H
            ACI   000H
            MOV   H,A

            MOV   A,M
            STA   DATETIME+00+00
            INX   H
            MOV   A,M
            STA   DATETIME+00+01
            INX   H
            MOV   A,M
            STA   DATETIME+00+02

            LDA   HOURS
            CALL  TODEC
            MOV   A,D
            STA   DATETIME+16+00
            MOV   A,E
            STA   DATETIME+16+01

            LDA   MINUTES
            CALL  TODEC
            MOV   A,D
            STA   DATETIME+19+00
            MOV   A,E
            STA   DATETIME+19+01

            LDA   SECONDS
            CALL  TODEC
            MOV   A,D
            STA   DATETIME+22+00
            MOV   A,E
            STA   DATETIME+22+01
            
            RET

TODEC:
            MVI   D,'0'
            MVI   E,'0'
            MVI   C,9

TODEC1      CPI   10
            JC    TODEC2
            INR   D
            SUI   10
TODEC2      DCR   C
            JNZ   TODEC1

            ADD   E
            MOV   E,A

            RET

TOBCD:
            MOV     D,A
            MVI     E,00H
            MVI     C,9

TOBCD1      MOV     A,D
            CPI     10
            JC      TOBCD2

            SUI     10
            MOV     D,A

            MOV     A,E
            ADI     10H
            MOV     E,A

            DCR     C
            JNZ     TOBCD1

TOBCD2      ORA     E

            RET

STRCMP:
            LDAX    D           ; DE=str1
            MOV     C,M         ; HL=str2
            CMP     C
            JNZ     STRCMP1
            INX     D
            INX     H
        
            ORA     A
            JNZ     STRCMP

STRCMP1     SUB     C           ; Z=equal
            RET

; Constants

AT          DB      'AT', 13, 10, 0
ATE0        DB      'ATE0', 13, 10, 0
CIPMUX      DB      'AT+CIPMUX=0', 13, 10, 0
CIPCLOSE    DB      'AT+CIPCLOSE', 13, 10, 0
CIPSTART    DB      'AT+CIPSTART="UDP","', 0
            DB      '",123', 13, 10, 0
CIPSEND     DB      'AT+CIPSEND=48', 13, 10, 0

STRSENDOK   DB      'SEND '
STROK       DB      'OK', 0
STRERROR    DB      'ERROR', 0

MONTHS      DB      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'
            DB      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'

WEEKDAYS    DB      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'

; Time zones

;TIMEDIFF    DB      000H, 000H, 000H, 000H  ; GMT
TIMEDIFF    DB      000H, 000H, 00EH, 010H  ; GMT+01

; Messages

ERR1        DB    'ESP-01 command error!', 13, 10, '$'
ERR2        DB    'Timeout waiting NTP packet. Retrying.', 13, 10, '$'
ERR3        DB    '^C$'

; Variables

TIMESTAMP   DB      0DEH, 038H, 0F0H, 01FH

YEAR        DB      00H
MONTH       DB      01H
DAY         DB      01H
WDAY        DB      07H
HOURS       DB      00H
MINUTES     DB      00H
SECONDS     DB      00H

DATETIME    DB      '--- -- --- 20-- --:--:--'
            DB      0AH, 0DH
            DB      '$'

SERVER      DB      'ntp.ubuntu.com', 0    ; default NTP server
            DS      64-15                  ; space for user-defined

FLAGS       DB      UPDATERTC

COUNT       DB      0
RETRYCNT    DB      0

BUFCNT      DB      0
BUFPTR      DW      0
BUF         DS      128

UDPCNT      DB      0
UDPBUF      DS      128

            END


