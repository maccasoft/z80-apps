; Propeller Graphics Card for RC2014
; https://github.com/maccasoft/propeller-graphics-card
;
; Sprite Animation Demo
;
; Compile:
;
;   TASM -80 -b SPRITE.ASM SPRITE.COM
;
; Copyright (c) 2018 Marco Maccaferri
; Tiles and sprites from BurgerTime (c) Data East Corp.

PORTC       .EQU    40H
PORTD       .EQU    41H
PORTS       .EQU    43H

SETMODE     .EQU    00H
SETTILBK    .EQU    06H
SETSPRBK    .EQU    07H
WRSPR       .EQU    0CH
WRMAP       .EQU    0DH
WRBMP       .EQU    0EH
WRMEM       .EQU    0FH

MODE1       .EQU    00H
MODE2       .EQU    01H
MODE3       .EQU    02H

PETER1      .EQU    07H
PETER2      .EQU    0BH
PETER3      .EQU    0FH
PETER4      .EQU    13H
PETER5      .EQU    17H

TILES_COUNT .EQU    27

            .ORG    0100H

            ; Set video mode

            LD      A,SETMODE
            OUT     (PORTC),A
            LD      A,MODE1
            OUT     (PORTD),A

            ; Clear all

            OUT     (PORTS),A

            LD      A,WRSPR
            OUT     (PORTC),A
            XOR     A
            OUT     (PORTD),A
            LD      B,32
L5          OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            DJNZ    L5

            LD      A,WRMAP
            OUT     (PORTC),A
            XOR     A
            OUT     (PORTD),A
            OUT     (PORTD),A

            LD      B,200
L6          OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            OUT     (PORTD),A
            DJNZ    L6

            ; Upload bitmaps

            LD      A,WRBMP
            OUT     (PORTC),A
            LD      A,00H
            OUT     (PORTD),A
            LD      A,00H
            OUT     (PORTD),A
            
            LD      HL,TILES
            LD      E,TILES_COUNT
            LD      C,PORTD
L2          LD      B,64
L1          OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            JP      NZ,L1
            DEC     E
            JP      NZ,L2

            ; Frame sync

            OUT     (PORTS),A

            ; Upload map

            LD      A,WRMAP
            OUT     (PORTC),A
            LD      A,20H           ; 0320H = Start from row 20
            OUT     (PORTD),A
            LD      A,03H
            OUT     (PORTD),A

            LD      HL,MAP
            LD      E,7             ; Writes 7 rows
            LD      C,PORTD
L4          LD      B,40
L3          OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            OUTI
            JP      NZ,L3
            DEC     E
            JP      NZ,L4

            ; Sprite enters from right side

LOOP1:      CALL    UPDATE

            LD      A,PETER2
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER1
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER2
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER3
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,B
            CP      0
            JP      NZ,LOOP1
            LD      A,C
            CP      152
            JP      NZ,LOOP1

            LD      A,PETER4
            LD      (FRAME),A
            CALL    UPDATE
            LD      E,30
            CALL    DELAY

            ; Animation at center

            LD      D,8
LOOP2:      LD      A,PETER5
            LD      (FRAME),A
            CALL    UPDATE

            LD      E,20
            CALL    DELAY

            LD      A,PETER4
            LD      (FRAME),A
            CALL    UPDATE

            LD      E,20
            CALL    DELAY

            DEC     D
            JP      NZ,LOOP2

            LD      A,PETER1
            LD      (FRAME),A

            ; Sprite exits to left side

LOOP3:      CALL    UPDATE

            LD      A,PETER2
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER1
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER2
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,PETER3
            LD      (FRAME),A
            CALL    UPDATE
            LD      BC,(XPOS)
            DEC     BC
            LD      (XPOS),BC

            LD      A,B
            CP      0FFH
            JP      NZ,LOOP3
            LD      A,C
            CP      0F0H
            JP      NZ,LOOP3

            RET

UPDATE:
            OUT     (PORTS),A       ; Frame sync

            LD      A,WRSPR         ; Initiate sprite data write
            OUT     (PORTC),A
            XOR     A
            OUT     (PORTD),A

            LD      A,(XPOS)        ; Sprite data
            OUT     (PORTD),A
            LD      A,(YPOS)
            OUT     (PORTD),A
            LD      A,(FRAME)
            OUT     (PORTD),A
            LD      A,(YPOS+1)      ; Position 9th bit + sprite flags
            AND     01H
            SLA     A
            LD      C,A
            LD      A,(XPOS+1)
            AND     01H
            OR      C
            OR      50H
            OUT     (PORTD),A

            OUT     (PORTS),A       ; Additional frame sync to add a bit
                                    ; of delay to the animation

            RET

DELAY:
            OUT     (PORTS),A
            DEC     E
            JP      NZ,DELAY
            RET

XPOS        .DW     320
YPOS        .DW     165
FRAME       .DB     PETER1

MAP:
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

            .DB     002H, 001H, 001H, 002H, 002H, 002H, 002H, 005H, 006H, 002H, 002H, 002H, 002H, 001H, 001H, 002H, 002H, 002H, 002H, 001H
            .DB     001H, 002H, 002H, 002H, 002H, 001H, 001H, 002H, 002H, 002H, 002H, 005H, 006H, 002H, 002H, 002H, 002H, 001H, 001H, 002H

            .DB     000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H
            .DB     004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H

            .DB     000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H
            .DB     004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H

            .DB     000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H
            .DB     004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H

            .DB     000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H
            .DB     004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H, 000H, 000H, 000H, 003H, 004H, 000H

TILES:
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H  ; 00
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 01
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH

            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H ; 02
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     00CH, 00CH, 00CH, 00CH, 00CH, 00CH, 00CH, 00CH
            .DB     00CH, 00CH, 00CH, 00CH, 00CH, 00CH, 00CH, 00CH

            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H ; 03
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H ; 04
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H

            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H ; 05
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 0A8H, 0A8H, 0A8H, 0A8H, 0A8H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH

            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H ; 06
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     0A8H, 0A8H, 0A8H, 0A8H, 0A8H, 000H, 000H, 000H
            .DB     000H, 000H, 000H, 000H, 000H, 000H, 000H, 000H
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH
            .DB     03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH, 03CH

            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH ; 07-0A
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0C0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0E0H, 0D0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 001H, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 0FCH, 0C0H, 0FCH, 0FCH, 0FCH
            .DB     001H, 0FCH, 0FCH, 060H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     0E0H, 0E0H, 0FCH, 030H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     0E0H, 0E0H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0D0H, 0D0H, 0D0H, 0D0H
            .DB     001H, 001H, 001H, 0D0H, 0D0H, 0D0H, 001H, 001H
            .DB     001H, 001H, 030H, 030H, 030H, 030H, 001H, 001H
            .DB     0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H
            .DB     0FCH, 0FCH, 0D0H, 0FCH, 0FCH, 0FCH, 0E0H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0D0H, 001H, 0E0H, 0E0H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0D0H, 0D0H, 0D0H, 0D0H, 001H, 001H, 001H, 001H
            .DB     001H, 0D0H, 0D0H, 0D0H, 0D0H, 060H, 001H, 001H
            .DB     001H, 001H, 001H, 060H, 060H, 001H, 001H, 001H

            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH ; 0B-0E
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0C0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0E0H, 0D0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 001H, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0C0H, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 0C0H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 0FCH, 001H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H
            .DB     001H, 001H, 001H, 001H, 001H, 030H, 030H, 030H
            .DB     0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0D0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0D0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0E0H, 0E0H, 0D0H, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0E0H, 0E0H, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     030H, 030H, 001H, 001H, 001H, 001H, 001H, 001H

            .DB     001H, 001H, 001H, 001H, 001H, 001H, 001H, 0FCH ; 0F-12
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 030H, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0C0H, 001H, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0E0H, 0D0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 001H, 0E0H, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 0E0H, 0E0H, 0FCH, 0FCH, 0FCH, 0D0H
            .DB     001H, 001H, 0E0H, 0E0H, 0D0H, 0D0H, 0D0H, 0FCH
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0D0H, 0D0H, 0D0H, 0D0H
            .DB     001H, 001H, 001H, 060H, 060H, 060H, 001H, 001H
            .DB     001H, 001H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 001H, 001H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0E0H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 0E0H, 0E0H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0D0H, 0D0H, 0D0H, 0D0H, 0D0H, 001H, 001H, 001H
            .DB     001H, 001H, 0D0H, 0D0H, 0D0H, 030H, 001H, 001H
            .DB     001H, 001H, 001H, 030H, 030H, 001H, 001H, 001H

            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH ; 13-16
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0C0H, 0C0H
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0D0H, 0E0H
            .DB     001H, 001H, 001H, 001H, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 001H, 0FCH, 0FCH, 0FCH, 0E0H, 0E0H, 0E0H
            .DB     001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     0FCH, 0FCH, 0FCH, 001H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     0FCH, 0FCH, 001H, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     0E0H, 0E0H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H, 001H
            .DB     001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H, 001H
            .DB     001H, 001H, 001H, 001H, 030H, 030H, 030H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0C0H, 0C0H, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 0FCH, 001H, 001H, 001H, 001H
            .DB     0E0H, 0D0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 0E0H, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 0FCH, 0FCH, 0FCH, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 0FCH, 0FCH, 0FCH
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 001H, 0FCH, 0FCH
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 0E0H, 0E0H
            .DB     001H, 0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H
            .DB     001H, 0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H
            .DB     001H, 030H, 030H, 030H, 001H, 001H, 001H, 001H

            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH ; 17-1A
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0C0H, 0C0H
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     0E0H, 0E0H, 001H, 001H, 0FCH, 0E0H, 0E0H, 0E0H
            .DB     0FCH, 0FCH, 001H, 001H, 0E0H, 0E0H, 0D0H, 0E0H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0E0H, 0E0H, 0E0H, 0E0H
            .DB     001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0C0H, 0FCH
            .DB     001H, 001H, 001H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     001H, 001H, 001H, 001H, 0D0H, 0D0H, 0D0H, 0D0H
            .DB     001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H, 001H
            .DB     001H, 001H, 001H, 001H, 001H, 0D0H, 0D0H, 001H
            .DB     001H, 001H, 001H, 001H, 030H, 030H, 030H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0C0H, 0C0H, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H, 001H
            .DB     0E0H, 0E0H, 0E0H, 0FCH, 001H, 001H, 0E0H, 0E0H
            .DB     0E0H, 0D0H, 0E0H, 0E0H, 001H, 001H, 0FCH, 0FCH
            .DB     0E0H, 0E0H, 0E0H, 0E0H, 0FCH, 0FCH, 0FCH, 0FCH
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H
            .DB     0FCH, 0C0H, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0FCH, 0FCH, 0FCH, 0FCH, 0FCH, 001H, 001H, 001H
            .DB     0D0H, 0D0H, 0D0H, 0D0H, 001H, 001H, 001H, 001H
            .DB     001H, 0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H
            .DB     001H, 0D0H, 0D0H, 001H, 001H, 001H, 001H, 001H
            .DB     001H, 030H, 030H, 030H, 001H, 001H, 001H, 001H

            .END

