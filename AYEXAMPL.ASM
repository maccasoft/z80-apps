; YM-2149 / AY-3-8912 Example Play Routine
;
; Based on the player from AYcog emulator written by Johannes Ahlebrand
; http://forums.parallax.com/showthread.php?122454
;
; Ported to Z80-CP/M by Marco Maccaferri <macca@maccasoft.com>
;
; Compile with:
;
;   TASM -80 -b AYEXAMPL.ASM AYEXAMPL.COM

ay_ctrl     .equ  0D8h              ; Sound chip control address
ay_data     .equ  0D0h              ; Sound chip data address

            .org  0100h

start:
            call  reset_registers
            
            ld    a,7               ; enable tone on ch.A and C
            out   (ay_ctrl),a       ; noise on ch.B
            ld    a,00101010b       
            out   (ay_data),a

            ld    a,11              ; set envelope rate to 845 (034Dh)
            out   (ay_ctrl),a
            ld    a,4Dh
            out   (ay_data),a
            ld    a,12
            out   (ay_ctrl),a
            ld    a,03h
            out   (ay_data),a
            
            ld    hl,music
l7:         call  play_sound

            push  hl

            ld    c,06h             ; get character from console
            ld    e,0FFh
            call  0005h
            
            pop   hl
            
            cp    03h               ; exit if CTRL-C
            jr    z,l7a
            cp    'q'               ; exit if q or Q
            jr    z,l7a
            cp    'Q'
            jr    z,l7a

            call  delay
            jr    l7

l7a:        call  reset_registers            
            ret

play_sound:
            ; channel 0
            ld    a,(hl)
            cp    255
            jr    nz,l4

            ld    hl,music
            ld    a,(hl)

l4:         inc   hl

            cp    0
            jr    z,l4a

            sub   43
            call  note2freq
            ld    a,0
            out   (ay_ctrl),a
            ld    a,c
            out   (ay_data),a
            ld    a,1
            out   (ay_ctrl),a
            ld    a,b
            out   (ay_data),a

            ld    a,15
            jr    l4b

l4a:        ld    a,(volume+0)
            sub   2
            jr    nc,l4b
            xor   a
l4b:        ld    (volume+0),a

            ld    a,8
            out   (ay_ctrl),a
            ld    a,(volume+0)
            out   (ay_data),a

            ; channel 1
            ld    a,(hl)
            cp    255
            jr    nz,l5

            ld    hl,music
            ld    a,(hl)

l5:         inc   hl

            cp    0
            jr    z,l5a

            ld    c,a
            ld    a,6
            out   (ay_ctrl),a
            ld    a,c
            out   (ay_data),a

            ld    a,13
            out   (ay_ctrl),a
            ld    a,0
            out   (ay_data),a

l5a:        ld    a,9
            out   (ay_ctrl),a
            ld    a,16
            out   (ay_data),a

            ; channel 2
            ld    a,(hl)
            cp    255
            jr    nz,l6

            ld    hl,music
            ld    a,(hl)

l6:         inc   hl

            cp    0
            jr    z,l6a

            sub   43
            call  note2freq
            ld    a,4
            out   (ay_ctrl),a
            ld    a,c
            out   (ay_data),a
            ld    a,5
            out   (ay_ctrl),a
            ld    a,b
            out   (ay_data),a

            ld    a,15
            jr    l6b

l6a:        ld    a,(volume+2)
            sub   2
            jr    nc,l6b
            xor   a
l6b:        ld    (volume+2),a

            ld    a,10
            out   (ay_ctrl),a
            ld    a,(volume+2)
            out   (ay_data),a

            ret

; BC = Frequency for note in A

note2freq:
            push  hl

            ld    d,a               ; Divide note by 12 (octave)
            ld    e,12
            call  div_d_e
            
            ld    b,0               ; D=octave, E=note
            ld    c,e
            ld    hl,note_table
            add   hl,bc
            add   hl,bc
            ld    c,(hl)
            inc   hl
            ld    b,(hl)
        
            ld    a,d
            cp    0
            jr    z,l3a
        
l3:         srl   b                 ; Shift frequency to octave
            rr    c
            dec   a
            jr    nz,l3

l3a:        pop   hl            
            ret

; Resets the sound chip regisers

reset_registers:
            ld    a,7
            out   (ay_ctrl),a
            ld    a,00111111b
            out   (ay_data),a

            ld    hl,reg_values
            ld    b,0
l2:         ld    a,b
            out   (ay_ctrl),a
            ld    a,(hl)
            out   (ay_data),a
            inc   b
            ld    a,b
            cp    14
            jr    nz,l2
            ret

reg_values: .db   0, 0            ; Default register values
            .db   0, 0
            .db   0, 0
            .db   0
            .db   00111111b
            .db   0, 0, 0
            .db   0, 0
            .db   0

; Note delay

delay:      push  bc
            ld    bc,13500
l1:         dec   bc
            ld    a,b
            or    c
            jr    nz,l1
            pop   bc
            ret

; 8-bit division and module
;
; D = D / E
; E = D % E

div_d_e:
            xor   a
            ld    b, 8

divl1:
            sla   d
            rla
            cp    e
            jr    c, $+4
            sub   e
            inc   d
   
            djnz  divl1
        
            ld    e,a
   
            ret

volume:
            .db     0, 0, 0

note_table:
            .dw     3087, 2914, 2750, 2596, 2450, 2312
            .dw     2183, 2060, 1945, 1835, 1732, 1635

music:
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     65,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     65,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0

            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     60,  0 , 0
            .db     60,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 0
            .db     0 ,  0 , 0

            .db     50,  31, 0
            .db     50,  0,  0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  8,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  8,  0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     55,  31, 0
            .db     55,  0,  0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     65,  8 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     65,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  8 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 0
            .db     0 ,  0 , 0

            .db     50,  31, 0
            .db     0 ,  0,  0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  8 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  8 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     60,  31, 0
            .db     60,  0,  0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  8 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  31, 0
            .db     0 ,  0 , 0
            .db     55,  8 , 0
            .db     55,  0 , 0
            .db     0 ,  31, 0
            .db     0 ,  0 , 0
            .db     67,  8 , 0
            .db     0 ,  0 , 0
            .db     67,  8 , 0
            .db     0 ,  0 , 0

            .db     50,  31, 0
            .db     50,  0,  0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  8 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  31, 86
            .db     0 ,  0,  86
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 93
            .db     0 ,  0,  93
            .db     0 ,  0 , 93
            .db     0 ,  0 , 93
            .db     50,  8 , 93
            .db     50,  0 , 93
            .db     0 ,  0 , 93
            .db     0 ,  0 , 93
            .db     62,  0 , 93
            .db     0 ,  0 , 93
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     55,  31, 79
            .db     55,  0,  79
            .db     55,  0 , 79
            .db     0 ,  0 , 79
            .db     55,  0 , 79
            .db     0 ,  0 , 79
            .db     0 ,  0 , 79
            .db     0 ,  0 , 79
            .db     65,  8 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  31, 77
            .db     0 ,  0,  77
            .db     0 ,  0 , 77
            .db     0 ,  0 , 77
            .db     65,  31, 77
            .db     0 ,  0,  77
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 83
            .db     55,  0 , 83
            .db     0 ,  0 , 83
            .db     0 ,  0 , 83
            .db     62,  8 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 0
            .db     0 ,  0 , 0

            .db     50,  31, 81
            .db     0 ,  0,  81
            .db     50,  0 , 81
            .db     0 ,  0 , 81
            .db     50,  0 , 81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     62,  8 , 81
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 79
            .db     50,  0 , 79
            .db     0 ,  0 , 79
            .db     0 ,  0 , 79
            .db     50,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 77
            .db     0 ,  0,  77
            .db     0 ,  0 , 77
            .db     0 ,  0 , 77
            .db     50,  8 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  0 , 84
            .db     0 ,  0 , 84
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     60,  31, 86
            .db     60,  0,  86
            .db     60,  0 , 86
            .db     0 ,  0 , 86
            .db     60,  31, 86
            .db     0 ,  0,  86
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  8 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 0
            .db     60,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  31, 89
            .db     0 ,  0,  89
            .db     0 ,  0 , 89
            .db     0 ,  0 , 89
            .db     67,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 88
            .db     55,  0 , 88
            .db     0 ,  31, 88
            .db     0 ,  0 , 88
            .db     67,  8 , 88
            .db     0 ,  0 , 88
            .db     67,  8 , 88
            .db     0 ,  0 , 88

            .db     50,  31, 88
            .db     50,  0,  88
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     62,  8 , 90
            .db     0 ,  0 , 89
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  0 , 81
            .db     50,  0 , 81
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  31, 89
            .db     0 ,  0,  88
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 89
            .db     0 ,  0,  89
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  8 , 81
            .db     50,  0 , 81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     62,  0 , 81
            .db     0 ,  0 , 81
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     55,  31, 84
            .db     55,  0,  84
            .db     55,  0 , 84
            .db     0 ,  0 , 84
            .db     55,  0 , 84
            .db     0 ,  0 , 84
            .db     0 ,  0 , 84
            .db     0 ,  0 , 84
            .db     65,  8 , 84
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  0 , 0
            .db     55,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  31, 83
            .db     0 ,  0,  83
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     65,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 79
            .db     55,  0 , 79
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  8 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 0
            .db     0 ,  0 , 0

            .db     50,  31, 86
            .db     0 ,  0,  86
            .db     50,  0 , 86
            .db     0 ,  0 , 86
            .db     50,  0 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     62,  8 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     0 ,  0 , 86
            .db     50,  0 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     50,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     62,  31, 82
            .db     0 ,  0,  81
            .db     0 ,  0 , 81
            .db     0 ,  0 , 81
            .db     50,  8 , 0
            .db     50,  0 , 0
            .db     0 ,  0 , 8
            .db     0 ,  0 , 79
            .db     62,  0 , 79
            .db     0 ,  0 , 79
            .db     62,  0 , 0
            .db     0 ,  0 , 0

            .db     60,  31, 82
            .db     60,  0,  81
            .db     60,  0 , 81
            .db     0 ,  0 , 81
            .db     60,  31, 81
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  8 , 84
            .db     0 ,  0 , 84
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     60,  0 , 8
            .db     60,  0 , 79
            .db     0 ,  0 , 79
            .db     0 ,  0 , 79
            .db     55,  31, 0
            .db     0 ,  0,  0
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     67,  0 , 79
            .db     0 ,  0 , 79
            .db     0 ,  0 , 0
            .db     0 ,  0 , 0
            .db     55,  8 , 77
            .db     55,  0 , 77
            .db     0 ,  31, 0
            .db     0 ,  0 , 0
            .db     67,  8 , 72
            .db     0 ,  0 , 72
            .db     67,  8 , 72
            .db     0 ,  0 , 72

            .db     255             ; Song end

            .end

