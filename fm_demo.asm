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
    ; from `fmsample.c` (http://www.dcee.net/Files/Programm/Sound/fmsample.zip)
    ; playing `A` tone (440Hz) on channel 1
	; - in `fm.asm` the corresponding "API" is `write_reg`.
    cmd.enable_waveform(0)
    cmd.feedback(CHANNEL.1, 0, 1)    ; paralel connection
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
    ;cmd.sustain_release(CARRIER_CELL, 05h)
    ;
    ; * Set parameters for the modulator cell *
    %define MODULATOR_CELL select_cell(1,1)

    cmd.main(MODULATOR_CELL, arg.main(0, 0, 1, 0))
    cmd.level(MODULATOR_CELL, arg.level(3, 0fh))
    cmd.atk_dcy(MODULATOR_CELL, arg.atk_dcy(4, 4)) ; scale is 0..0fh
    cmd.sustain_release(MODULATOR_CELL, arg.sustain_release(0,5)) 
    ;* Generate tone from values looked up in table. *
    cmd.tone(CHANNEL.1, TONE.A, OCTAVE.DEFAULT)
.wait_key:
    call waitKey
    test al, al
    je .wait_key

	;fm(0xb0,0x12);  /* key off */
    cmd.key_off(CHANNEL.1) ; note that in original it's ("key off" | 2) - ??? 


    mov ax, 4c00h
    int 21h