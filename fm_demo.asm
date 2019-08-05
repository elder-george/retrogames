;entry point
global start

%include 'common.inc'
%include 'fm.asm'

; in kb.asm
extern getKey
extern checkKey
extern waitKey

section code
start:
    mov ax, data
    mov ds, ax
    ; from `fmsample.c` (http://www.dcee.net/Files/Programm/Sound/fmsample.zip)
    ; playing `A` tone (440Hz) on channel 1
	; - in `fm.asm` the corresponding "API" is `write_reg`.
    cmd.enable_waveform(0)

    jmp near .play_from_data
    cmd.feedback(CHANNEL.1, arg.feedback(0, 1))    ; paralel connection
    ; * Set parameters for the carrier cell *
    %define CARRIER_CELL  select_cell(1, 2)
    ; * no amplitude modulation (D7=0), no vibrato (D6=0),
    ; * sustained envelope type (D5=1), KSR=0 (D4=0),
    ; * frequency multiplier=1 (D4-D0=1)
    cmd.main(CARRIER_CELL, arg.main(0, 0, 1, 0) | 1)
	; no volume decrease with pitch (D7-D6=0)
    cmd.level(CARRIER_CELL, arg.level(0, 0))
	;fast attack (D7-D4=0xF) and decay (D3-D0=0xF)
    cmd.atk_dcy(CARRIER_CELL, arg.atk_dcy(0fh, 0fh))
    ;high sustain level (D7-D4=0), slow release rate (D3-D0=5) 
    cmd.sustain_release(CARRIER_CELL, arg.sustain_release(0, 5))

    ; * Set parameters for the modulator cell *
    %define MODULATOR_CELL select_cell(1,1)

    cmd.main(MODULATOR_CELL, arg.main(0, 0, 1, 0))
    cmd.level(MODULATOR_CELL, arg.level(3, 0fh))
    cmd.atk_dcy(MODULATOR_CELL, arg.atk_dcy(4, 4))
    cmd.sustain_release(MODULATOR_CELL, arg.sustain_release(0,5)) 
    ;* Generate tone from values looked up in table. *
    cmd.tone(CHANNEL.1, TONE.A, OCTAVE.DEFAULT)
    jmp .wait_key

.play_from_data:
    ;push 0
    push track.1
    call play_track
    sub sp, 2
.wait_key:
    call waitKey
    test al, al
    je .wait_key
	; * key off
    cmd.key_off(CHANNEL.1)
.exit:
    mov ax, 4c00h
    int 21h

%macro do_cmd 1
    mov bl, ADDR.BASE.%1
    call play_track.do_cmd_impl
%endm


play_track:
    .TRACK_START equ 4
    .MOVE_TO_NEXT equ -2
    push bp
    mov bp, sp
    add sp, 2
    mov si, [bp + .TRACK_START]
    mov di, si
.header:
    xor bx, bx
    mov bh, [si + TRACK_HDR.channel]
    push bx      ; backup 
    xor dx, dx
    mov cl, [si+TRACK_HDR.tone_no]
    mov ch, [si+TRACK_HDR.counter]
    cmp ch, 0
    jge .continue_current
.move_to_next:
    inc cl
    mov [si+TRACK_HDR.tone_no], cl
    mov [bp+.MOVE_TO_NEXT], cl
.continue_current:
    mov al, TONE_size      ; skip first N tones...
    mov ah, cl
    mul ah
    add ax, TRACK_HDR_size ; ...in addition to header
    add si, ax             ; si -> tone data
    cld
.track:
    lodsb        ; tone's length - skip for now
    mov ah, [bp+.MOVE_TO_NEXT]
    test ah, ah
    jz .play
.reset_counter:
    mov [di+TRACK_HDR.counter], al
.play:
    do_cmd FDBK_CONN_TYPE
    ; CARRIER CELL
    or bh, OP_OFFSET.2
    do_cmd MAIN
    do_cmd LEVEL
    do_cmd ATK_DCY
    do_cmd SUST_REL
    ; restore channel# - and save it again
    pop bx
    push bx
    ; MODULATOR_CELL
    or bh, OP_OFFSET.1
    do_cmd MAIN
    do_cmd LEVEL
    do_cmd ATK_DCY
    do_cmd SUST_REL
    ; restore base channel address one last time
    pop bx
    do_cmd FREQ
    do_cmd KEY_OCTAVE_FREQ

.exit:
    mov sp, bp
    pop bp
    ret

; expects:
; - SI to point at the FM command list
; - BH to have cell #
; - BL to have register address
.do_cmd_impl:
    or bl, bh
    lodsb
    ; write_reg uses `al` to pass register "address" to the FM chip
    ; so, passing address through `al` is safe, passing data isn't
    xchg bl, al
    write_reg al, bl
    ret

fm.timer2.enable:
    cmd.timer_reset_all
    cmd.timer.load(0, 1)
    cmd.timer.2(195)
    ret

fm.timer2.disable:
    cmd.timer_disable(1, 1)
    ret

; IN: NULL-terminated array of TRACKS
fm.timer_handler:
    %define .TRACKS equ 4
    push bp
    mov bp, sp
    ; check if this is a FM-device timer:
    read_status
    test al, 10100000b
    jz .exit ; not something else?
    ; update the tracks state
    mov si, [bp+TRACKS]
.foreach_track:
    lodsw
    test ax, ax
    jz .exit
    push ax
    call play_tone
    jmp .foreach_track
.exit:
    mov sp, bp
    pop bp
    ret
    
section data

struc CELL_CFG
    .main       resb 1
    .level      resb 1
    .atk_decay  resb 1
    .sus_rel    resb 1
endstruc

struc TONE
    .len         resb 1 ;??? 156*320us = 49.9ms ~= 1/20s; 195*320us =~ 62.5ms = 1/16s etc
    .feedback    resb 1
    .carrier_cfg resb CELL_CFG_size
    .mod_cfg     resb CELL_CFG_size
    .tone_oct    resw 1
endstruc

struc TRACK_HDR
    .channel resb 1
    .counter resb 1
    .tone_no resb 1
endstruc

track.1:
istruc TRACK_HDR
    at TRACK_HDR.channel, db CHANNEL.1
    at TRACK_HDR.counter, db 07fh    ; initial value - max<int8>
    at TRACK_HDR.tone_no, db 0
iend
.tones:
    istruc TONE
        at TONE.len,            db 16
        at TONE.feedback,       db arg.feedback(0, 1)
        at TONE.carrier_cfg,    db (arg.main(0, 0, 1, 0) | 1), arg.level(0, 0), arg.atk_dcy(0fh, 0fh), arg.sustain_release(0, 5)
        at TONE.mod_cfg,        db arg.main(0, 0, 1, 0), arg.level(3, 0fh), arg.atk_dcy(04h, 04h), arg.sustain_release(0,5)
        at TONE.tone_oct,       dw make_tone_octave(TONE.A, OCTAVE.DEFAULT)
    iend

    istruc TONE
        at TONE.len,            db 16
        at TONE.feedback,       db arg.feedback(0, 1)
        at TONE.carrier_cfg,    db (arg.main(0, 0, 1, 0) | 1), arg.level(0, 0), arg.atk_dcy(0fh, 0fh), arg.sustain_release(0, 5)
        at TONE.mod_cfg,        db arg.main(0, 0, 1, 0), arg.level(3, 0fh), arg.atk_dcy(04h, 04h), arg.sustain_release(0,5)
        at TONE.tone_oct,       dw make_tone_octave(TONE.D, OCTAVE.DEFAULT)
    iend
