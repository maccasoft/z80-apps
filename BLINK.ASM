; I/O Board LED blink
;
; Compile:
;
;   C:ASM BLINK
;   C:LOAD BLINK

PORT        EQU     00H

LED0        EQU     01H
LED1        EQU     02H
LED2        EQU     04H
LED3        EQU     08H
LED4        EQU     10H
LED5        EQU     20H
LED6        EQU     40H
LED7        EQU     80H
LEDALL      EQU     0FFH

BDOS        EQU     0005H

            ORG     0100H

LOOP:
            MVI     A,255       ; turn on all LEDs
            OUT     PORT
            CALL    DELAY       ; delay
            CPI     03H         ; return if CTRL-C pressed
            JZ      EXIT

            MVI     A,0         ; turn off all LEDs
            OUT     PORT
            CALL    DELAY       ; delay
            CPI     03H         ; return if CTRL-C pressed
            JZ      EXIT
            
            JMP     LOOP

EXIT:
            MVI     A,0         ; turn off all LEDs
            OUT     PORT

            MVI     C,09H       ; display a message
            LXI     D,MSG1
            CALL    BDOS
            RET

DELAY:
            LXI     B,800H
L1          PUSH    B
            MVI     C,06H       ; check console status
            MVI     E,0FFH
            CALL    BDOS
            POP     B

            CPI     03H         ; return if CTRL-C
            RZ

            DCX     B
            MOV     A,B
            ORA     C
            JNZ     L1

            XRA     A
            RET

MSG1:       DB      '^C$'

            END

