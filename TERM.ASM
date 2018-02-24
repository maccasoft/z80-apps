; Very Dumb Terminal for RC2014
; Copyright (c) 2018 by Marco Maccaferri
;
; Compile on CP/M with:
;
;   C:ASM TERM
;   C:LOAD TERM
;
; Invoke with:
;
;   TERM [/E] [/L]
;
;   /E - Enable local echo
;   /L - Enable LF after CR

AUXST:      EQU   0E956H
AUXRB:      EQU   0E966H
AUXWB:      EQU   0E9E0H

CR:         EQU   13
LF:         EQU   10

            ORG   0100H
            
            LXI   H,80H     ; parse command line flags
            MOV   C,M
            INR   C

L4:         INX   H
            DCR   C
            JZ    L5
            MOV   A,M
            CPI   '/'
            JNZ   L4

            INX   H
            DCR   C
            JZ    L5

            MOV   A,M
            ANI   5FH       ; uppercase
            CPI   'E'
            JZ    L6
            CPI   'L'
            JZ    L7
            JMP   L4

L6:         LDA   ECHO
            XRI   01H
            STA   ECHO
            JMP   L4
            
L7:         LDA   CRLF
            XRI   01H
            STA   CRLF
            JMP   L4
            
L5:         LXI   D,SIGNON
            MVI   C,09H
            CALL  0005H

L1:         CALL  AUXST     ; check if byte available
            ORA   A
            JZ    L2

            CALL  AUXRB     ; receive byte

            MVI   C,02H     ; display on console
            MOV   E,A
            CALL  0005H

L2:         MVI   C,06H     ; get character from console
            MVI   E,0FFH
            CALL  0005H

            ORA   A         ; nothing ready, loop
            JZ    L2
            CPI   03H       ; CTRL-C exit
            JZ    EXIT

            CALL  AUXWBE    ; write to remove and console
            CPI   CR
            JNZ   L1

            LDA   CRLF      ; check if LF should be appended
            ORA   A
            JZ    L1

            MVI   A,LF      ; send LF
            CALL  AUXWBE

            JMP   L1

EXIT:
            RET

AUXWBE:
            PUSH  PSW
            MOV   C,A
            CALL  AUXWB

            LDA   ECHO
            ORA   A
            JZ    L3

            POP   PSW
            PUSH  PSW

            MVI   C,02H
            MOV   E,A
            CALL  0005H

L3:         POP   PSW

            RET

SIGNON:     DB    12
            DB    'Very Dumb Terminal', 13, 10
            DB    'Press CTRL-C to exit', 13, 10
            DB    13, 10, '$'

CRLF        DB    0
ECHO        DB    0

            END
