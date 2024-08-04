		ORG     0f000h

;--------------------------------------------------
; Code executed after Reset
;--------------------------------------------------
		di      			; disable interrupt
		xor     a			; set a to zero
restime:	dec     a			; do 256 times nothing
		jr      nz, restime		; loop 
		
		ld      hl, portval		; init 11 ports with values at 0a3h
		ld      b, 0bh              
portinit:	ld      c, (hl)             
		inc     hl                 
		outi   			 	 
		jr      nz, portinit		; loop



;--------------------------------------------------
; 11 times port:value
;--------------------------------------------------
portval:	db	050h, 001h			;Bit0	set ATARI DATA
		db	051h, 001h			;Bit1	set RS232 TX
		db	080h, 003h			;CTC	Channel 0 reset
		db 	080h, 010h			;CTC	Channel 0 interrupt vector
		db	081h, 007h			;CTC	Channel 1 reset + set time constant
		db	081h, 001h			;CTC	Channel 1 time contant 1
		db	082h, 003h			;CTC	Channel 2 reset
		db	083h, 003h			;CTC	Channel 3 reset
		db	057h, 001h			;Bit7	ATARI RXD
		db	030h, 000h			;DSE	Floppy Control (74LS273)
		db	040h, 0d0h			;DWR/DRW	FDC read-write	d0 = force int (with no interrupt)
		
		