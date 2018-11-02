global fm_init
global fm_close
global fm_play

%define PORT_ADDRESS 	0388h
%define PORT_STATUS		0388h
%define PORT_DATA	 	0389h

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
	out al, dx
	delay_address
	inc dx
	mov al, VAL
	out al, dx
	delay_data
%endmacro

%macro read_status
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
%define ADDR.BASE.FREQ		A0h
%define ADDR.BASE.KEY_OCTAVE_FREQ	B0h
%define ADDR.BASE.FDBK_CONN_TYPE	C0h
%define ADDR.DEPTH_RHYTHM	BDh
%define ADDR.WAVE_SELECT	E0h


%define CHANNEL_OFFSET.1	00h
%define CHANNEL_OFFSET.2	01h
%define CHANNEL_OFFSET.3	02h
%define CHANNEL_OFFSET.4	08h
%define CHANNEL_OFFSET.5	09h
%define CHANNEL_OFFSET.6	0ah
%define CHANNEL_OFFSET.7	10h
%define CHANNEL_OFFSET.8	11h
%define CHANNEL_OFFSET.9	12h

%define OP_OFFSET.1	0h
%define OP_OFFSET.2 1h

%define select_reg(base, channel, op) base + CHANNEL_OFFSET.%channel + OP_OFFSET.%op

%define field(v, size, shift) (v& -(1<<size))<<shift

%define cmd.timer.1(delay80us) 		write_reg ADDR.TIMER_ONE, (256-delay80us)
%define cmd.timer.2(delay320us) 	write_reg ADDR.TIMER_TWO, (256-delay320us)
%define cmd.timer_reset_all 				write_reg ADDR.TIMER_CTL, (1<<7)
; only applies if timer.N is 1
%define cmd.timer_disable(timer.1, timer.2) write_reg ADDR.TIMER_CTL, \
	field(~timer.1, 1, 6)|field(~timer.2, 5)<<5)| 00b
%define cmd.timer.load(timer.1, timer.2) write_reg ADDR.TIMER_CTL, \
	field(~timer.1, 1, 6)|field(~timer.2, 5)<<5) | 11b

; Don't want to implement ADDR.SPEECH_KEYB


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

%define arg.main(use_amp, use_vib, no_decay, harmonic) \
	field(use_amp, 1, 7)|field(use_vib,1,6)|field(no_decay,1,5) | field(harmonic, 4, 0)
%define cmd.main(channel, op, arg)\
	write_reg select_reg(ADDR.BASE.MAIN, channel, op), arg
%define arg.level(scaling, total)	field(scaling,2,6)|field(total,6,0)
%define cmd.level(channel, op, arg)
	write_reg select_reg(ADD.BASE.LEVEL, channel, op), arg
%define arg.atk_dcy(atk, dcy) field(atk,4,4)|field(dcy, 4, 0)