;--------------------------------------------------
; out\ ports
;--------------------------------------------------
; $2x 	Printer DATA
; $3x	Port Floppy Control
; $4x	FDC 1797
; $5x	U52 74LS259
; 	$50	ATARI Out data
; 	$51	RS232 TX
; 	$52	ROM switch
; 	$53	printer strobe
; 	$54	reset index-pulse
; 	$55	RS232 DTR
; 	$56	set index pulse
; 	$57	0=CMD,  1=SIO
; $8x	CTC
;--------------------------------------------------
; in\ ports
;--------------------------------------------------
; $2x	Printer Control
; $4x	FDC 1797
; $5x	RS232	D7=RX,  D3=1,  D2=?,  D1=FlowControl
; $70	SIO	D7=RX,  D3=RDY/+5V, D1=CMD
;--------------------------------------------------
;
LF		equ	0ah
CR		equ	0dh

RXD		equ	050h
TXD		equ	051h

VARS		equ	0fff0h
echo		equ	0
sum		equ	1
addr		equ	2


		ORG     0000h

start:		ld	b, 0
start1:		djnz	start1

;		jp	ramtest
		
		ld	sp, VARS

		ld	hl, 0				;copy 8k from 0 to 8000h
		ld	de, 08000h
		ld	bc, 02000h
		ldir
		
		ld	hl, copy
		set	7, h
		jp	(hl)

copy:		ld	a, 1				;switch	ROM off
		out 	(52h), a
		
		ld	hl, 08000h			;copy 8k from 8000h to 0
		ld	de, 0h
		ld	bc, 02000h
		ldir

		ld	hl, monitor
		res	7, h
		jp	(hl)
		
monitor:	
		include	"sallytest.asm"

		
;--------------------------------------------------
;--------------------------------------------------
;--------------------------------------------------
		IFDEF exclude
;--------------------------------------------------
;--------------------------------------------------
;--------------------------------------------------
		
ramtest:
		ld	a, 1				;stop bit
		out	(TXD), a
		
		ld	a, 0aah
;ramtest4:	ld	e, 10
;		
;ramtest2:	out	(30h), a
;		ld	d, a
;ramtest1:	inc	bc
;		ld	a, b
;		or	c
;		jnz	ramtest1
;		ld	a, d
;		cpl	a
;		dec	e
;		jr	nz, ramtest2
;
;		ld	a, 'A'
;		ld	hl, ramtest3
;		jp	putchar
;
;ramtest3:	ld	a, 1
;		jp 	ramtest4



		exx
		ld	hl, 08000h
		exx
	
		ld	c, 0
		ld	hl, 08000h
start2:		ld	(hl), c
		dec	c
		inc	hl
		ld	a, h
		or	a, l
		jp	nz, start2

		ld	a, 10
		ld	hl, start5
		jp	putchar
		
start5:		ld	d, 16
start4:		ld	e, 16
start3:		jp	puthex
label1:		exx
		inc	hl
		exx
		ld	a, ' '
		ld	hl, label2
		jp	putchar
label2:		dec	e
		jp	nz, start3
newline:	ld	a, 10
		ld	hl, label3
		jp	putchar
label3:		dec	d
		jp	nz, start4
		
		ld	hl, end
		ld	a, 10
		jp	putchar
end:		jp	start5

puthex:		exx
		ld	a, (hl)
		exx
		rra
		rra
		rra
		rra
		and	15
		cp	10
		jr	c, putnib1
		add	7
putnib1:	add	'0'
		ld	hl, putnib2
		jp	putchar
putnib2:	exx
		ld	a, (hl)
		exx
		and	15
		cp	10
		jr	c, putnib3
		add	7
putnib3:	add	'0'
		ld	hl, label1
		
putchar:	or	a
		rla
		ld	c, 8
		out	(TXD), a
		rra
		ld	b, 14
loop0:		djnz	b, loop0
loop2:		out	(TXD), a
		rrca	
		ld	b, 14
loop1:		djnz	loop1
		dec	c
		jp	nz, loop2
		or	a
		ccf
		rla
		out	(TXD), a
		rra
		ld	b, 15
loop5:		djnz	loop5
		jp	(hl)
			

test:		ret	

		ENDIF