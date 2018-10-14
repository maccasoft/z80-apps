; Program:    date.asm
; Author:     Marco Maccaferri
; Date:       16 Feb 2018
; Enviroment: TASM MS-DOS Z80 Cross Assembler source for CP/M

MASK_DATA   .EQU    %10000000               ; RTC data line
MASK_CLK    .EQU    %01000000               ; RTC Serial Clock line
MASK_RD     .EQU    %00100000               ; Enable data read from RTC
MASK_RST    .EQU    %00010000               ; De-activate RTC reset line

RTC         .EQU    $C0                     ; RTC port

BDOS        .EQU    5                       ; BDOS invocation vector

BUF_WDAY    .EQU    00                      ; Formatted date/time positions
BUF_DAY     .EQU    04
BUF_MONTH   .EQU    07
BUF_YEAR    .EQU    13
BUF_HOUR    .EQU    16
BUF_MIN     .EQU    19
BUF_SEC     .EQU    22


            .ORG    0100H

            CALL    RTC_RESET_ON

            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY

            CALL    RTC_GET_TIME
            LD      DE,RTC_PRINT_BUFFER
            LD      C,09H                   ; CP/M write string to console call
            CALL    0005H

            RET


; RTC_GET_TIME
; uses A,C,D,E
; result in RTC_PRINT_BUFFER

RTC_GET_TIME:
            DI                              ; disable interrupts during DS1302 read
            CALL    RTC_RESET_OFF           ; turn off RTC reset

;           { Write command, burst read }

            LD      C,%10111111             ; (255 - 64)
            CALL    RTC_WR                  ; send COMMAND BYTE (BURST READ) to DS1302

;           { Read seconds }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            RRA      
            RRA
            RRA
            RRA
            AND     $07
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_SEC+00),A

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_SEC+01),A

;           { Read minutes }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            RRA      
            RRA
            RRA
            RRA
            AND     $07
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_MIN+00),A

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_MIN+01),A

;           { Read hours }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            RRA      
            RRA
            RRA
            RRA
            AND     $03
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_HOUR+00),A

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_HOUR+01),A

;           { Read date }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            RRA      
            RRA
            RRA
            RRA
            AND     $03
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_DAY+00),A

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_DAY+01),A

;           { Read month }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C
            
            LD      HL,MONTHS
            LD      A,C
            AND     $1F
            CP      $10
            JR      C,L2
            AND     $0F
            ADD     A,$0A
L2:         LD      C,A
            LD      B,0
            DEC     BC
            ADD     HL,BC
            ADD     HL,BC
            ADD     HL,BC

            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_MONTH+00),A
            INC     HL
            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_MONTH+01),A
            INC     HL
            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_MONTH+02),A

;           { Read weekday }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $07
            LD      C,A
            LD      B,0
            DEC     BC
            LD      HL,WEEKDAYS
            ADD     HL,BC
            ADD     HL,BC
            ADD     HL,BC

            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_WDAY+00),A
            INC     HL
            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_WDAY+01),A
            INC     HL
            LD      A,(HL)
            LD      (RTC_PRINT_BUFFER+BUF_WDAY+02),A

;           { Read year }

            CALL    RTC_RD                  ; read value from DS1302, value is in Reg C

            LD      A,C                     ; put value output in Reg C into accumulator
            RRA      
            RRA
            RRA
            RRA
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_YEAR+00),A

            LD      A,C                     ; put value output in Reg C into accumulator
            AND     $0F
            ADD     A,'0'
            LD      (RTC_PRINT_BUFFER+BUF_YEAR+01),A

            CALL    RTC_RESET_ON            ; turn RTC reset back on 
            EI                              ; re-enable interrupts

            RET                             ; Yes, end function and return

; RTC_RESET
;
; Output a RTC reset signal

RTC_RESET:
            LD      A,MASK_DATA | MASK_RD
            OUT    (RTC),A
            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY
            LD      A,MASK_DATA | MASK_RD | MASK_RST
            OUT    (RTC),A
            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY
            RET

; RTC_RESET_ON
;
; Assert RTC reset signal

RTC_RESET_ON:
            LD      A,MASK_DATA | MASK_RD
            OUT    (RTC),A
            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY
            RET

; RTC_RESET_OFF
;
; De-assert RTC reset signal

RTC_RESET_OFF:
            LD      A,MASK_DATA | MASK_RD | MASK_RST
            OUT    (RTC),A
            CALL    RTC_BIT_DELAY
            CALL    RTC_BIT_DELAY
            RET

; output value in C
; uses A
RTC_WR:
            XOR     A                       ; set A=0 index counter of FOR loop

RTC_WR1:    PUSH    AF                      ; save accumulator as it is the index counter in FOR loop
            LD      A,C                     ; get the value to be written in A from C (passed value to write in C)
            BIT     0,A                     ; is LSB a 0 or 1?
            JP      Z,RTC_WR2               ; if it's a 0, handle it at RTC_WR2.
                                            ; LSB is a 1, handle it below
                                            ; setup RTC latch with RST and DATA high, SCLK low
            LD      A,MASK_RST | MASK_DATA
            OUT    (RTC),A                  ; output to RTC latch
            ;CALL    RTC_BIT_DELAY           ; let it settle a while
                                            ; setup RTC with RST, DATA, and SCLK high
            LD      A,MASK_RST | MASK_CLK | MASK_DATA
            OUT    (RTC),A                  ; output to RTC latch
            JP      RTC_WR3                 ; exit FOR loop 

RTC_WR2:    LD      A,MASK_RST              ; setup RTC latch with RST high, SCLK and DATA low
            OUT    (RTC),A                  ; output to RTC latch
            ;CALL    RTC_BIT_DELAY           ; let it settle a while
                                            ; setup RTC with RST and SCLK high, DATA low
            LD      A,MASK_RST | MASK_CLK
            OUT    (RTC),A                  ; output to RTC latch

RTC_WR3:    ;CALL    RTC_BIT_DELAY           ; let it settle a while
            RRC     C                       ; move next bit into LSB position for processing to RTC
            POP     AF                      ; recover accumulator as it is the index counter in FOR loop
            INC     A                       ; increment A in FOR loop (A=A+1)
            CP      $08                     ; is A < $08 ?
            JP      NZ,RTC_WR1              ; No, do FOR loop again
            RET                             ; Yes, end function and return

; input value in C
; uses A
RTC_RD:
            XOR     A                       ; set A=0 index counter of FOR loop
            LD      C,$00                   ; set C=0 output of RTC_RD is passed in C
            LD      B,$01                   ; B is mask value

RTC_RD1:    PUSH    AF                      ; save accumulator as it is the index counter in FOR loop
                                            ; setup RTC with RST and RD high, SCLK low
            LD      A,MASK_RST | MASK_RD
            OUT    (RTC),A                  ; output to RTC latch
            ;CALL    RTC_BIT_DELAY           ; let it settle a while
            IN     A,(RTC)                  ; input from RTC latch
            BIT     0,A                     ; is LSB a 0 or 1?
            JP      Z,RTC_RD2               ; if LSB is a 1, handle it below
            LD      A,C
            ADD     A,B
            LD      C,A
;            INC     C
                                            ; if LSB is a 0, skip it (C=C+0)
RTC_RD2:    RLC     B                       ; move input bit out of LSB position to save it in C
                                            ; setup RTC with RST, SCLK high, and RD high
            LD      A,MASK_RST | MASK_CLK | MASK_RD
            OUT    (RTC),A                  ; output to RTC latch
            ;CALL    RTC_BIT_DELAY           ; let it settle
            POP     AF                      ; recover accumulator as it is the index counter in FOR loop
            INC     A                       ; increment A in FOR loop (A=A+1)
            CP      $08                     ; is A < $08 ?
            JP      NZ,RTC_RD1              ; No, do FOR loop again
            RET                             ; Yes, end function and return.  Read RTC value is in C

; RTC_BIT_DELAY
;
; Make a short delay

RTC_BIT_DELAY:                              ; purpose is to delay ~36 uS or 144 t-states at 4MHz
            PUSH    AF                      ; 11 t-states
            LD      A,07H                   ; 7 t-states ADJUST THE TIME 13h IS FOR 4 MHZ

L1:         DEC     A                       ; 4 t-states DEC COUNTER. 4 T-states = 1 uS.
            JP      NZ,L1                   ; 10 t-states JUMP TO PAUSELOOP2 IF A <> 0.

            NOP                             ; 4 t-states
            NOP                             ; 4 t-states
            POP     AF                      ; 10 t-states
            RET                             ; 10 t-states (144 t-states total)

MONTHS:                                     ; Month short names
            .DB     "Jan"
            .DB     "Feb"
            .DB     "Mar"
            .DB     "Apr"
            .DB     "May"
            .DB     "Jun"
            .DB     "Jul"
            .DB     "Aug"
            .DB     "Sep"
            .DB     "Oct"
            .DB     "Nov"
            .DB     "Dec"

WEEKDAYS:                                   ; Weekday short names
            .DB     "Sun"
            .DB     "Mon"
            .DB     "Tue"
            .DB     "Wed"
            .DB     "Thu"
            .DB     "Fri"
            .DB     "Sat"

RTC_PRINT_BUFFER:                           ; Buffer for formatted date & time to print
            .DB     "--- -- --- 20-- --:--:--"
            .DB     0Ah, 0Dh                ; line feed and carriage return
            .DB     "$"                     ; line terminator

            .END

