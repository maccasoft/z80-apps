;==================================================================================
; CP/M Loader ROM for RC2014
; by Marco Maccaferri <macca@maccasoft.com>
;
; Based on Grant Searle's Z80 Monitor
; http://searle.hostei.com/grant/index.html
;
: Modifications:
;
;  * Removed code to detect the active console
;  * Removed the hex loader and basic options
;  * Added delay to allow slow peripherals to be ready
;    and discard all incoming characters
;  * Turn off the leds on the digital I/O board
;  * Primary console is always SIOA
;==================================================================================

; General Equates
CR              .EQU    0DH
LF              .EQU    0AH
ESC             .EQU    1BH
CTRLC           .EQU    03H
CLS             .EQU    0CH

; CF registers
CF_DATA         .EQU    $10
CF_FEATURES     .EQU    $11
CF_ERROR        .EQU    $11
CF_SECCOUNT     .EQU    $12
CF_SECTOR       .EQU    $13
CF_CYL_LOW      .EQU    $14
CF_CYL_HI       .EQU    $15
CF_HEAD         .EQU    $16
CF_STATUS       .EQU    $17
CF_COMMAND      .EQU    $17
CF_LBA0         .EQU    $13
CF_LBA1         .EQU    $14
CF_LBA2         .EQU    $15
CF_LBA3         .EQU    $16

; CF Features
CF_8BIT         .EQU    1
CF_NOCACHE      .EQU    082H
; CF Commands
CF_READ_SEC     .EQU    020H
CF_WRITE_SEC    .EQU    030H
CF_SET_FEAT     .EQU    0EFH


loadAddr        .EQU    0D000h  ; CP/M load address
numSecs         .EQU    24      ; Number of 512 sectors to be loaded


SER_BUFSIZE     .EQU    40H
SER_FULLSIZE    .EQU    30H
SER_EMPTYSIZE   .EQU    5

RTS_HIGH        .EQU    0E8H
RTS_LOW         .EQU    0EAH

SIOA_D          .EQU    $81
SIOA_C          .EQU    $80
SIOB_D          .EQU    $83
SIOB_C          .EQU    $82

                .ORG    $4000
serABuf         .ds     SER_BUFSIZE
serAInPtr       .ds     2
serARdPtr       .ds     2
serABufUsed     .ds     1
serBBuf         .ds     SER_BUFSIZE
serBInPtr       .ds     2
serBRdPtr       .ds     2
serBBufUsed     .ds     1

primaryIO       .ds     1
secNo           .ds     1
dmaAddr         .ds     2

stackSpace      .ds     32
STACK           .EQU    $       ; Stack top


;------------------------------------------------------------------------------
;                         START OF MONITOR ROM
;------------------------------------------------------------------------------

MON             .ORG    $0000           ; MONITOR ROM RESET VECTOR
;------------------------------------------------------------------------------
; Reset
;------------------------------------------------------------------------------
RST00           DI                      ;Disable INTerrupts
                JP      INIT            ;Initialize Hardware and go
                NOP
                NOP
                NOP
                NOP
;------------------------------------------------------------------------------
; TX a character over RS232 wait for TXDONE first.
;------------------------------------------------------------------------------
RST08           JP      conout
                NOP
                NOP
                NOP
                NOP
                NOP
;------------------------------------------------------------------------------
; RX a character from buffer wait until char ready.
;------------------------------------------------------------------------------
RST10           JP      conin
                NOP
                NOP
                NOP
                NOP
                NOP
;------------------------------------------------------------------------------
; Check input buffer status
;------------------------------------------------------------------------------
RST18           JP      CKINCHAR

;------------------------------------------------------------------------------
; SIO Vector = 0x60
;------------------------------------------------------------------------------

                .ORG    $0060
                .DW     serialInt


;------------------------------------------------------------------------------
; Serial interrupt handlers
; Same interrupt called if either of the inputs receives a character
; so need to check the status of each SIO input.
;------------------------------------------------------------------------------
serialInt:      PUSH    AF
                PUSH    HL

                ; Check if there is a char in channel A
                ; If not, there is a char in channel B
                SUB     A
                OUT     (SIOA_C),A
                IN      A,(SIOA_C)      ; Status byte D2=TX Buff Empty, D0=RX char ready        
                RRCA                    ; Rotates RX status into Carry Flag,    
                JR      NC, serialIntB

serialIntA:
                LD      HL,(serAInPtr)
                INC     HL
                LD      A,L
                CP      (serABuf+SER_BUFSIZE) & $FF
                JR      NZ, notAWrap
                LD      HL,serABuf
notAWrap:
                LD      (serAInPtr),HL
                IN      A,(SIOA_D)
                LD      (HL),A

                LD      A,(serABufUsed)
                INC     A
                LD      (serABufUsed),A
                CP      SER_FULLSIZE
                JR      C,rtsA0
                LD      A,$05
                OUT     (SIOA_C),A
                LD      A,RTS_HIGH
                OUT     (SIOA_C),A
rtsA0:
                POP     HL
                POP     AF
                EI
                RETI

serialIntB:
                LD      HL,(serBInPtr)
                INC     HL
                LD      A,L
                CP      (serBBuf+SER_BUFSIZE) & $FF
                JR      NZ, notBWrap
                LD      HL,serBBuf
notBWrap:
                LD      (serBInPtr),HL
                IN      A,(SIOB_D)
                LD      (HL),A

                LD      A,(serBBufUsed)
                INC     A
                LD      (serBBufUsed),A
                CP      SER_FULLSIZE
                JR      C,rtsB0
                LD      A,$05
                OUT     (SIOB_C),A
                LD      A,RTS_HIGH
                OUT     (SIOB_C),A
rtsB0:
                POP     HL
                POP     AF
                EI
                RETI

;------------------------------------------------------------------------------
; Console input routine
; Use the "primaryIO" flag to determine which input port to monitor.
;------------------------------------------------------------------------------
conin:
                PUSH    HL
                LD      A,(primaryIO)
                CP      0
                JR      NZ,coninB
coninA:

waitForCharA:
                LD      A,(serABufUsed)
                CP      $00
                JR      Z, waitForCharA
                LD      HL,(serARdPtr)
                INC     HL
                LD      A,L
                CP      (serABuf+SER_BUFSIZE) & $FF
                JR      NZ, notRdWrapA
                LD      HL,serABuf
notRdWrapA:
                DI
                LD      (serARdPtr),HL

                LD      A,(serABufUsed)
                DEC     A
                LD      (serABufUsed),A

                CP      SER_EMPTYSIZE
                JR      NC,rtsA1
                LD      A,$05
                OUT     (SIOA_C),A
                LD      A,RTS_LOW
                OUT     (SIOA_C),A
rtsA1:
                LD      A,(HL)
                EI

                POP     HL

                RET     ; Char ready in A


coninB:

waitForCharB:
                LD      A,(serBBufUsed)
                CP      $00
                JR      Z, waitForCharB
                LD      HL,(serBRdPtr)
                INC     HL
                LD      A,L
                CP      (serBBuf+SER_BUFSIZE) & $FF
                JR      NZ, notRdWrapB
                LD      HL,serBBuf
notRdWrapB:
                DI
                LD      (serBRdPtr),HL

                LD      A,(serBBufUsed)
                DEC     A
                LD      (serBBufUsed),A

                CP      SER_EMPTYSIZE
                JR      NC,rtsB1
                LD      A,$05
                OUT     (SIOB_C),A
                LD      A,RTS_LOW
                OUT     (SIOB_C),A
rtsB1:
                LD      A,(HL)
                EI

                POP     HL

                RET     ; Char ready in A

;------------------------------------------------------------------------------
; Console output routine
; Use the "primaryIO" flag to determine which output port to send a character.
;------------------------------------------------------------------------------
conout:         PUSH    AF              ; Store character
                LD      A,(primaryIO)
                CP      0
                JR      NZ,conoutB1
                JR      conoutA1
conoutA:
                PUSH    AF

conoutA1:       CALL    CKSIOA          ; See if SIO channel A is finished transmitting
                JR      Z,conoutA1      ; Loop until SIO flag signals ready
                POP     AF              ; RETrieve character
                OUT     (SIOA_D),A      ; OUTput the character
                RET

conoutB:
                PUSH    AF

conoutB1:       CALL    CKSIOB          ; See if SIO channel B is finished transmitting
                JR      Z,conoutB1      ; Loop until SIO flag signals ready
                POP     AF              ; RETrieve character
                OUT     (SIOB_D),A      ; OUTput the character
                RET

;------------------------------------------------------------------------------
; I/O status check routine
; Use the "primaryIO" flag to determine which port to check.
;------------------------------------------------------------------------------
CKSIOA
                SUB     A
                OUT     (SIOA_C),A
                IN      A,(SIOA_C)      ; Status byte D2=TX Buff Empty, D0=RX char ready        
                RRCA                    ; Rotates RX status into Carry Flag,    
                BIT     1,A             ; Set Zero flag if still transmitting character 
                RET

CKSIOB
                SUB     A
                OUT     (SIOB_C),A
                IN      A,(SIOB_C)      ; Status byte D2=TX Buff Empty, D0=RX char ready        
                RRCA                    ; Rotates RX status into Carry Flag,    
                BIT     1,A             ; Set Zero flag if still transmitting character 
                RET

;------------------------------------------------------------------------------
; Check if there is a character in the input buffer
; Use the "primaryIO" flag to determine which port to check.
;------------------------------------------------------------------------------
CKINCHAR
                LD      A,(primaryIO)
                CP      0
                JR      NZ,ckincharB

ckincharA:

                LD      A,(serABufUsed)
                CP      $0
                RET

ckincharB:

                LD      A,(serBBufUsed)
                CP      $0
                RET

;------------------------------------------------------------------------------
; Filtered Character I/O
;------------------------------------------------------------------------------

RDCHR           RST     10H
                CP      LF
                JR      Z,RDCHR         ; Ignore LF
                CP      ESC
                JR      NZ,RDCHR1
                LD      A,CTRLC         ; Change ESC to CTRL-C
RDCHR1          RET

WRCHR           CP      CR
                JR      Z,WRCRLF        ; When CR, write CRLF
                CP      CLS
                JR      Z,WR            ; Allow write of "CLS"
                CP      ' '             ; Don't write out any other control codes
                JR      C,NOWR          ; ie. < space
WR              RST     08H
NOWR            RET

WRCRLF          LD      A,CR
                RST     08H
                LD      A,LF
                RST     08H
                LD      A,CR
                RET


;------------------------------------------------------------------------------
; Initialise hardware and start main loop
;------------------------------------------------------------------------------
INIT            LD      SP,STACK        ; Set the Stack Pointer

                LD      HL,serABuf
                LD      (serAInPtr),HL
                LD      (serARdPtr),HL

                LD      HL,serBBuf
                LD      (serBInPtr),HL
                LD      (serBRdPtr),HL

                XOR     A
                LD      (serABufUsed),A
                LD      (serBBufUsed),A

; Initialise SIO

                LD      A,$00
                OUT     (SIOA_C),A
                LD      A,$18
                OUT     (SIOA_C),A

                LD      A,$04
                OUT     (SIOA_C),A
                LD      A,$C4
                OUT     (SIOA_C),A

                LD      A,$01
                OUT     (SIOA_C),A
                LD      A,$18
                OUT     (SIOA_C),A

                LD      A,$03
                OUT     (SIOA_C),A
                LD      A,$E1
                OUT     (SIOA_C),A

                LD      A,$05
                OUT     (SIOA_C),A
                LD      A,RTS_LOW
                OUT     (SIOA_C),A

                LD      A,$00
                OUT     (SIOB_C),A
                LD      A,$18
                OUT     (SIOB_C),A

                LD      A,$04
                OUT     (SIOB_C),A
                LD      A,$C4
                OUT     (SIOB_C),A

                LD      A,$01
                OUT     (SIOB_C),A
                LD      A,$18
                OUT     (SIOB_C),A

                LD      A,$02
                OUT     (SIOB_C),A
                LD      A,$60           ; INTERRUPT VECTOR ADDRESS
                OUT     (SIOB_C),A
        
                LD      A,$03
                OUT     (SIOB_C),A
                LD      A,$E1
                OUT     (SIOB_C),A

                LD      A,$05
                OUT     (SIOB_C),A
                LD      A,RTS_LOW
                OUT     (SIOB_C),A

                ; Interrupt vector in page 0
                LD      A,$00
                LD      I,A

                IM      2
                EI

; Resets I/O board output

                XOR     A
                OUT     (0),A
                OUT     (1),A
                OUT     (2),A
                OUT     (3),A

; Send clear screen on both consoles

                LD      A,$00
                LD      (primaryIO),A
                LD      A,CLS
                RST     08H
                LD      A,$01
                LD      (primaryIO),A
                LD      A,CLS
                RST     08H

; Check warm-boot (experimental)

                LD      A,($FFE8)
                CP      $3E
                JR      NZ,WAIT
                LD      A,($FFE9)
                CP      $01
                JR      Z,CPMLOAD

; Wait for slow peripherals to start-up

WAIT
                LD      D,2
                LD      BC,0
l4:             PUSH    DE
l3:             PUSH    BC

                CALL    ckincharA
                jr      Z,l1
                LD      A,$00
                LD      (primaryIO),A
                CALL    conin

l1:             CALL    ckincharB
                JR      Z,l2
                LD      A,$01
                LD      (primaryIO),A
                CALL    conin
                
l2:             POP     BC
                DEC     BC
                LD      A,B
                OR      C
                JR      NZ,l3
                POP     DE
                DEC     D
                JR      NZ,l4

; Set primary console to SIOA and load CP/M

CPMLOAD
                LD      A,$00
                LD      (primaryIO),A
                LD      HL,CPMTXT
                CALL    PRINT

                CALL    cfWait
                LD      A,CF_8BIT       ; Set IDE to be 8bit
                OUT     (CF_FEATURES),A
                LD      A,CF_SET_FEAT
                OUT     (CF_COMMAND),A

                CALL    cfWait
                LD      A,CF_NOCACHE    ; No write cache
                OUT     (CF_FEATURES),A
                LD      A,CF_SET_FEAT
                OUT     (CF_COMMAND),A

                LD      B,numSecs

                LD      A,0
                LD      (secNo),A
                LD      HL,loadAddr
                LD      (dmaAddr),HL

processSectors:
                CALL    cfWait

                LD      A,(secNo)
                OUT     (CF_LBA0),A
                LD      A,0
                OUT     (CF_LBA1),A
                OUT     (CF_LBA2),A
                LD      a,0E0H
                OUT     (CF_LBA3),A
                LD      A,1
                OUT     (CF_SECCOUNT),A

                CALL    READ

                LD      DE,0200H
                LD      HL,(dmaAddr)
                ADD     HL,DE
                LD      (dmaAddr),HL
                LD      A,(secNo)
                INC     A
                LD      (secNo),A

                DJNZ    processSectors

; Start CP/M using entry at top of BIOS
; The current active console stream ID is pushed onto the stack
; to allow the CBIOS to pick it up
; 0 = SIO A, 1 = SIO B
                
                LD      A,(primaryIO)
                PUSH    AF
                LD      HL,($FFFE)
                JP      (HL)


CPMTXT:         .BYTE   $0D,$0A
                .TEXT   "Loading CP/M..."
                .BYTE   $0D,$0A,$00

;------------------------------------------------------------------------------

; Read physical sector from host

READ:
                PUSH    AF
                PUSH    BC
                PUSH    HL

                CALL    cfWait

                LD      A,CF_READ_SEC
                OUT     (CF_COMMAND),A

                CALL    cfWait

                LD      c,4
                LD      HL,(dmaAddr)
rd4secs:
                LD      b,128
rdByte:
                nop
                nop
                in      A,(CF_DATA)
                LD      (HL),A
                iNC     HL
                dec     b
                JR      NZ, rdByte
                dec     c
                JR      NZ,rd4secs

                POP     HL
                POP     BC
                POP     AF

                RET


; Wait for disk to be ready (busy=0,ready=1)

cfWait:
                PUSH    AF
cfWait1:
                in      A,(CF_STATUS)
                AND     080H
                cp      080H
                JR      Z,cfWait1
                POP     AF
                RET

;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
PRINT           LD      A,(HL)     ; Get character
                OR      A          ; Is it $00 ?
                RET     Z          ; Then RETurn on terminator
                RST     08H        ; Print it
                INC     HL         ; Next Character
                JR      PRINT      ; Continue until $00

TXCRLF          LD      A,$0D      ; 
                RST     08H        ; Print character 
                LD      A,$0A      ; 
                RST     08H        ; Print character
                RET

;------------------------------------------------------------------------------

FINIS           .END    

