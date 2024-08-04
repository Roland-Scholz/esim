conout		equ	chrout
conin		equ	chrin

;--------------------------------------------------------------
; print menu
; print prompt
; read upper key
; check if key is found in menukey
; read jmp-address and jump to subroutine
;--------------------------------------------------------------
printmenu:
		ld	a, 1
		ld	(VARS + echo), a
		ld	ix, VARS
		
		ld      HL, menutext
		call	printstr

printprompt:		
		call	newline
		ld	c, '>'
		call	printaddr
	
enterkey:	
		ld	c, 0			;offset in jumptable
		ld	HL, menukey		;number auf keys
		ld	b, (HL)			;in b
		inc	HL
		call	getupper		;read upper key
enterkey2: 
		cp	(HL)			;key found?
		jr	Z, enterkey1		;yes ==>
		inc	HL
		inc	c
		inc	c
		djnz	enterkey2		;decrease b and jump
		jr	enterkey
enterkey1:	
		ld	b, 0			;add offset in BC
		ld	HL, menutab		;to base
		add	HL, BC
		ld	BC, printprompt		;push return-address
		push	BC
		ld	e, (HL)			;load jp address in DE
		inc	HL
		ld	d, (HL)
		ex	DE, HL			;in HL now
		jp	(HL)
	
;--------------------------------------------------------------
; jump to printmenu
;--------------------------------------------------------------
questionmark:
		pop	BC
		jp	printmenu
		
;--------------------------------------------------------------
; jump to (addr)
;--------------------------------------------------------------
goto:		ld	HL, (VARS + addr)
		jp	(HL)
	
;--------------------------------------------------------------
; Disassemble 22 lines starting from (addr)
;--------------------------------------------------------------
disass:
		ld	B, 22
		ld	DE, (VARS + addr)
		call	newline
disass1:
		push	BC
		call	DISASM
		call	newline
		pop	BC
		djnz	disass1
		
		ld	(VARS + addr), DE	;save new address
		ret
		
;--------------------------------------------------------------
; change a byte in (addr)
;--------------------------------------------------------------
changebyte:
		ld	HL, (VARS + addr)
		ld	a, (HL)
		call	printhex
		ld	a, ':'
		call	conout
		call	gethexbyte
		ld	(HL), a
		ret

;--------------------------------------------------------------
; 
;--------------------------------------------------------------
fillmem:
		ld	HL, filltext
		call	printstr
		
		call	gethexbyte		;get from-addr
		ld	h, a
		call	gethexbyte
		ld	l, a
		push	HL
		push	HL
		
		ld	HL, lentext
		call	printstr
		call	gethexbyte		;get length
		ld	b, a
		call	gethexbyte
		ld	c, a
		
		ld	a, b			; if BC = 0
		or	a, c
		ret	Z			; return	
		dec	BC
		
		ld	HL, withtext
		call	printstr
		call	gethexbyte
		
		pop	DE			; DE = HL + 1
		inc	DE
		
		pop	HL
		ld	(HL), a 
		
		ld	a, b
		or	a, c
		ret	Z
		
		LDIR
		
		ret

;--------------------------------------------------------------
; 
;--------------------------------------------------------------
transfer:	
		ld	HL, transtext
		call	printstr
		
		call	gethexbyte		;get from-addr
		ld	h, a
		call	gethexbyte
		ld	l, a
		push	HL
		
		ld	HL, lentext
		call	printstr
		call	gethexbyte		;get length
		ld	b, a
		call	gethexbyte
		ld	c, a

		ld	HL, totext
		call	printstr
		call	gethexbyte		;get dest-addr
		ld	d, a
		call	gethexbyte
		ld	e, a

		pop	HL
		
		LDIR
		
		ret
		
;--------------------------------------------------------------
; read new address from conin
;--------------------------------------------------------------
newaddress:
		ld	HL, addrtext
		call	printstr
		call	gethexbyte
		ld	(VARS + addr + 1), a
		call	gethexbyte
		ld	(VARS + addr), a
		ret
		
;--------------------------------------------------------------
; dump 256 bytes starting from (HL)
;--------------------------------------------------------------
dumpmem:
		call	newline
		ld	d, 16
		ld	HL, (VARS + addr)
	
dumpline:
		ld	c, ':'
		call	printaddr
		
		call	space
		push	HL
		
		ld	b, 16
dumpmem1:
		ld	a, (HL)
		inc	HL
		call	printhex
		call	space
		ld	a, b
		cp	9
		jr	NZ, dumpmem3
		call	space
dumpmem3:	
		djnz	dumpmem1
		
		
		ld	a, '|'
		call	chrout
		ld	b, 16
		pop	HL
	
dumpmem5:
		ld	a, (HL)
		inc	HL
		cp	32
		jr	C, dumpmem6
		cp	126
		jr	C, dumpmem4
dumpmem6:
		ld	a, '.'
dumpmem4:
;		ld	c, a
		call	chrout
		djnz	dumpmem5
		
		ld	a, '|'
		call	chrout
		
		call	newline
		ld	(VARS + addr), hl
		dec	d
		jr	NZ, dumpline
		ret		

;--------------------------------------------------------------
; binary download to 0f000h
;--------------------------------------------------------------
download:	ld	hl, 0f000h
		ld	(VARS + addr), hl
		
download1:	call	rs232in
		ld	(hl), a				;7
		inc	hl				;6
		jp	download1			;10
			
rs232in:	in	a, (RXD)			;11	bit 7, wait for start-bit (0)
		rla					;4
		jr	c, rs232in			;12/7	22
		nop
		nop
		ld	d, 8
		ld	b, 22				;7
		djnz	ASMPC				;13/8
rs232in1:	in	a, (RXD)			;11
		rla					;4
		rr	c				;8
		ld	b, 13				;7
		djnz	ASMPC				;13
		dec	d				;4
		jr	nz, rs232in1			;12/7
		ld	a, c				;4
		ret


;--------------------------------------------------------------
; input char in A
;--------------------------------------------------------------
chrin:		push	bc
		push	de
chrin4:		in	a, (RXD)			;11	bit 7, wait for start-bit (0)
		rla					;4
		jr	c, chrin4			;12/7	22
		ld	d, 8
		ld	b, 22				;7
chrin1:		djnz	b, chrin1			;13/8
chrin3:		in	a, (RXD)			;11
		rla					;4
		rr	c				;8
		ld	b, 13				;7
chrin2:		djnz	chrin2				;13
		dec	d				;4
		jr	nz, chrin3			;12/7
		ld	a, c				;4
		pop	de
		pop	bc
		ret

;chrin:		in	a, (TXD)
;		bit	3, a
;		jr	nz, chrin		;wait for start bit
;chrin2:		push	bc
;		push	de
;		ld	b, 8
;		call	t19200h		
;chrin1:		call	t19200
;		in	a, (TXD)
;		rra
;		rra
;		rra
;		rra
;		rr	d
;		djnz	chrin1
;		ld	a, d
;		pop	de
;		pop	bc
;		ret
		
;--------------------------------------------------------------
; output char in A
;--------------------------------------------------------------
chrout:		push	bc
		push	de
		ld	d, a
		xor	a
		out	(TXD), a
		ld	a, d
		ld	b, 14
		djnz	ASMPC
		ld	c, 8
chrout1:	out	(TXD), a
		rrca
		ld	b, 14
		djnz	ASMPC
		dec	c
		jr	nz, chrout1
		ld	a, 1
		out	(TXD), a
		ld	b, 30
		djnz	ASMPC
		ld	a, d
		pop	de
		pop	bc
		ret

;chrout:		push	bc			;4.000.000 / 19200 = 208
;		push	af
;		push	af
;		xor	a			;208 - 77 = 131
;		ld	b, 8
;		out	(TXD), a		;send start bit
;		call	t19200			
;		pop	af
;chrout1:	out	(TXD), a		;11
;		rrca				;4
;		call	t19200			;17
;		djnz	chrout1			;12		
;		ld	a, 1			;stop bit
;		out	(TXD), a
;		call	t19200
;		pop	af
;		pop	bc
;		ret
;
;t19200h:	ld	c, 1
;		jr	t19200a
;t19200:		ld	c, 9			;7
;t19200a:	dec	c			;4
;		jr	nz, t19200a		;12
;		ret				;10
;
;time:		push	af
;		push	hl
;		ld	hl, 0
;time1:		dec	hl
;		ld	a, h
;		or	a, l
;		jr	nz, time1
;		pop	hl
;		pop	af
;		ret
;

;--------------------------------------------------------------
; gethexbyte
; returns 00-FF in A
; uses E
;--------------------------------------------------------------
gethexbyte:
		push	DE
		call	getnibble
		rlca
		rlca
		rlca
		rlca
		ld	e, a
		call	getnibble
		or	e
		ld	e, a
		add	a, (IX + sum)
		ld	(VARS + sum), a
		ld	a, e
		pop	DE
		ret

	
;--------------------------------------------------------------
; calls conin
; returns 0-F in A
;--------------------------------------------------------------
getnibble:
		call	conin
		push	AF
		ld	a, (VARS + echo)
		or	a
		jr	Z, getnibble2
		pop	AF
		push	AF
		push	BC
;		ld	c, a
		call	conout
		pop	BC
getnibble2:
		pop	AF	
		sub	'0'
		cp	10		; < 10 ?
		ret	C		; yes, return
		and	11011111b	; make uppercase
		sub	7
		ret

;--------------------------------------------------------------
; print text in (HL) uses
; A
;--------------------------------------------------------------
printstr:
		push	BC
printstr2:
		ld	a, (HL)
		inc	HL
		or	a
		jr	Z, printstr1
		call	chrout
		cp	CR
		jr	NZ, printstr2
		ld	a, LF
		call	chrout
		jr	printstr2
printstr1:
		pop	BC
		ret

;--------------------------------------------------------------
; 
;--------------------------------------------------------------
printaddr:
		ld	a, (VARS + addr + 1)
		call	printhex
		ld	a, (VARS + addr)
		call	printhex
		ld	a, c
		jp	conout
		
;--------------------------------------------------------------
; 
;--------------------------------------------------------------
printhl:
		ld	a, h
		call	printhex
		ld	a, l
		call	printhex
		jp	space

;--------------------------------------------------------------
; prints byte in A in hexadecimal format
;--------------------------------------------------------------
printhex:
		push    AF
		push    AF
		rra
		rra
		rra
		rra
		call    printnib
		pop     AF
		call    printnib
		pop     AF
		ret
printnib:
		and     0fh
		cp      0ah
		jr      C, printnib1
		add     a, 07h
printnib1:
		add     a, '0'
print:
		jp    chrout
		
newline:
		ld      a, CR
		call    chrout
		ld      a, LF
		jp    	chrout

space:
		push	af
		ld	a, ' '
		call	chrout
		pop	af
		ret
		
getupper:
		call	conin
		cp	'a'
		ret	C
		sub	32
		ret
		
sallystart:	DB	32, 27, "[m", CR
		DB	"*************************************************", CR
		DB	"***  ", 27, "[1mSally-1", 27, "[m     Start                        ***", CR
		DB	"*************************************************", CR
		DB	0
		
downtext:	DB	"downloading...", CR, 0
;downendtext:	DB	"finished.", CR, 0
addrtext:	DB	"address:", 0
;errortext:	DB	"error!", 0
transtext:	DB	"transfer from:", 0
lentext:	DB	" len:", 0
totext:		DB	" to:", 0
filltext:	DB	"fill from:", 0
withtext:	DB	" with:", 0
;disktext:	DB	"enter disk number (0-9):",0
;filetext:	DB	CR, "filename:",0		
menukey:
		DB	8
		DB	"?CDFGLMN"

menutab:
		DW	questionmark
		DW	changebyte
		DW	download
;		DW	closedisk
		DW	fillmem
		DW	goto
		DW	disass
		DW	dumpmem
		DW	newaddress
;		DW	opendisk
;		DW	cpm
;		DW	transfer
;		DW	vt102
;		DW	exit
menutext:
		DB	32, 27, "[m", CR
		DB	"*************************************************", CR
		DB	"***  Z80 Mini-Monitor  (c) '22  by ", 27, "[1mR. Scholz", 27,"[m  ***", CR
		DB	"*************************************************", CR
		DB	"? - This text", CR
		DB	"C - Change byte", CR
		DB	"D - Download to 0f000h", CR
;		DB	"E - Close Disk", CR
		DB	"F - Fill memory", CR
		DB	"G - Goto address", CR
		DB	"L - Disassemble", CR
		DB	"M - Memory dump", CR
		DB	"N - New address", CR
;		DB	"O - Open Disk", CR
;		DB	"P - CP/M", CR
;		DB	"T - Transfer memory", CR
;		DB	"V - VT102 test", CR
;		DB	"X - eXit", CR
		DB	0
		
		include "C:\github\FABIAN\src\disz80.asm"
