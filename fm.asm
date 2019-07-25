global fm_init
global fm_close
global fm_play

;;; based on http://bochs.sourceforge.net/techspec/adlib_sb.txt et al

%define PORT_ADDRESS 	0388h
%define PORT_STATUS		PORT_ADDRESS
%define PORT_DATA	 	PORT_ADDRESS+1

%macro delay 1
	mov cl, %1
%%delay.loop: 
	in al, dx
	dec cl
	jne %%delay.loop
%endm

%define delay_address 	delay 6 
%define delay_data 		delay 35


%macro write_reg 2
%define REG %1
%define VAL %2
	mov dx, PORT_ADDRESS
	mov al, REG
	out dx, al
	delay_address
	inc dx
	mov al, VAL
	out dx, al
    dec dx
	delay_data
%endmacro

%macro read_status 0
	mov dx, PORT_STATUS
	in ax, dx
%endm

; `read_status` result has these bits set if timers had expired
%define TIMER_BOTH 	10000000b
%define TIMER_ONE 	01000000b
%define TIMER_TWO 	00100000b

%define ADDR.TEST_ENABLE 	01h
%define ADDR.TIMER_ONE	 	02h
%define ADDR.TIMER_TWO	 	03h
%define ADDR.TIMER_CTL		04h
%define ADDR.SPEECH_KEYB	08h
%define ADDR.BASE.MAIN		20h
%define ADDR.BASE.LEVEL		40h
%define ADDR.BASE.ATK_DCY	60h
%define ADDR.BASE.SUST_REL	80h
%define ADDR.BASE.FREQ		0A0h
%define ADDR.BASE.KEY_OCTAVE_FREQ	0B0h
%define ADDR.BASE.FDBK_CONN_TYPE	0C0h
%define ADDR.DEPTH_RHYTHM	0BDh
%define ADDR.WAVE_SELECT	0E0h


%define CHANNEL.1	00h
%define CHANNEL.2	01h
%define CHANNEL.3	02h
%define CHANNEL.4	08h
%define CHANNEL.5	09h
%define CHANNEL.6	0ah
%define CHANNEL.7	10h
%define CHANNEL.8	11h
%define CHANNEL.9	12h

%define OP_OFFSET.1	0h
%define OP_OFFSET.2 3h

%define select_cell(channel, op) CHANNEL.%+channel | OP_OFFSET.%+op

%define select_reg(base, cell) ADDR.BASE.%+base | cell
; macro to ensure the bitfield doesn't spill outside of allowed space
; I really tried to use bit number instead of masks, but couldn't figure 
; the right formula for, like, 10 minutes, so scratch that.
%define field(v, mask, shift) (v& mask)<<shift

%define cmd.timer.1(delay80us) 		write_reg ADDR.TIMER_ONE, (256-delay80us)
%define cmd.timer.2(delay320us) 	write_reg ADDR.TIMER_TWO, (256-delay320us)
%define cmd.timer_reset_all 				write_reg ADDR.TIMER_CTL, (1<<7)
; only applies if timer.N is 1
%define cmd.timer_disable(timer.1, timer.2) write_reg ADDR.TIMER_CTL, \
	field(~timer.1, 1, 6)|field(~timer.2, 1, 5)| 00b
%define cmd.timer.load(timer.1, timer.2) write_reg ADDR.TIMER_CTL, \
	field(~timer.1, 1, 6)|field(~timer.2, 5) | 11b

; Don't want to implement ADDR.SPEECH_KEYB

%define TONE.C_SHARP 16Bh   ; 277.2Hz
%define TONE.D       181h   ; 293.7Hz
%define TONE.D_SHARP 198h   ; 311.1Hz
%define TONE.E       1B0h   ; 329.6Hz
%define TONE.F       1CAh   ; 349.2Hz
%define TONE.F_SHARP 1E5h   ; 370.0Hz
%define TONE.G       202h   ; 392.0Hz
%define TONE.G_SHARP 220h   ; 415.3Hz
%define TONE.A       241h   ; 440.0Hz
%define TONE.A_SHARP 263h   ; 466.2Hz
%define TONE.B       287h   ; 493.9Hz
%define TONE.C       2Aeh   ; 523.3Hz

%define OCTAVE.DEFAULT 4

%define HARM.MINUS_1 	0
%define HARM.UNISON 	1
%define HARM.1			2
%define HARM.1_5TH		3
%define HARM.2			4
%define HARM.2_MAJ_3RD	5
%define HARM.2_5TH		6
%define HARM.2_MAJ_7TH	7
%define HARM.3			8
%define HARM.3_MAJ_2ND	9
%define HARM.3_MAJ_3RD	0Ah
%define HARM.3_5TH		0Ch
%define HARM.3_MAJ_7TH	0Eh

%define ALG.MODULATE 0
%define ALG.DIRECT  1

%define cmd.enable_waveform(wf)\
    write_reg ADDR.TEST_ENABLE, field(wf, 1b, 5)

%define arg.feedback(strength, alg)     field(strength, 111b, 1)|field(alg, 1, 0)
%define cmd.feedback(channel, arg)\
    write_reg ADDR.BASE.FDBK_CONN_TYPE|channel, arg

%define arg.main(use_amp, use_vib, no_decay, harmonic) \
	field(use_amp, 1, 7)|field(use_vib,1b,6)|field(no_decay,1b,5) | field(harmonic,01111b, 0)
%define cmd.main(cell, arg)\
	write_reg select_reg(MAIN, cell), arg
%define arg.level(scaling, total)	field(scaling,11b,6)|field(total,111111b,0)
%define cmd.level(cell, arg)\
	write_reg select_reg(LEVEL, cell), arg
%define arg.atk_dcy(atk, dcy) field(atk,1111b,4)|field(dcy, 1111b, 0)
%define cmd.atk_dcy(cell, arg)\
    write_reg select_reg(ATK_DCY, cell), arg
%define arg.sustain_release(sust_level, rel_rate) field(sust_level, 1111b, 4)|field(rel_rate, 1111b, 0)
%define cmd.sustain_release(cell, arg)\
    write_reg select_reg(SUST_REL, cell), arg
%define arg.tone2(tone, octave) (field(1, 1, 5)|field(octave,111b, 2)|field((tone>>8),11b,0))
%macro cmd_tone 3
%define channel %1
%define tone    %2
%define octave  %3
    write_reg select_reg(FREQ, channel), (tone&0ffh)
    write_reg select_reg(KEY_OCTAVE_FREQ, channel), arg.tone2(tone, octave)
%endmacro

; Opposite operation: build a word describing octave & tone in a format that can be written to the regs
%define make_tone_octave(tone, octave) ((arg.tone2(tone,octave)<<8) | (tone & 0ffh))


%define cmd.tone(cell, tone, octave) cmd_tone cell, tone, octave
%define cmd.key_off(cell) write_reg select_reg(KEY_OCTAVE_FREQ, cell), field(0,1,5)

section code

section data
