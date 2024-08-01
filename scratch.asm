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
		
		
		ld      hl,0f000h          
		ld      a, 01h              
testram2:	ld      b, 10h			; test ram @F000-FFFF
testram:	ld      (hl),a
		rlca    
		inc     l
		jr      nz, testram
		inc     h
		djnz    testram
		
		ld      c, 10h
testram1:	dec     hl
		rrca    
		cp      (hl)
ramerr:		jr      nz, ramerr		; if error, loop forever
		djnz    testram1              
		dec     c                  
		jr      nz, testram1           
		add     a, a                
		jr      nz, testram2
		


;loop:		ld	a, 'A'
;		call	conout
;		jr	loop
					
		ld      hl, 0			; copy rom to ram
		ld      de, 0			
		ld      bc, 02000h        	   
		ldir                    	   
		
		ld      hl, sallycode		; copy BIOS from $00b9 to $f000
		ld      de, 0f000h		; length efc
		ld      bc, 0efch        	   
		ldir                    	   
		ld      hl, vars		;sallycode + 0fb5h - 0b9h ; copy from fb5 to $ff20
		ld      de, 0ff20h		; length $2F
		ld      bc, 002fh        	   
		ldir                    	   
						
		xor     a			; fill up to $FFFF with zeros
ramfill:	ld      (de),a             
		inc     e                  
		jr      nz, ramfill           
					
		ld      sp,0ff10h		; stack-pointer to 0ff10h
		
		ld      a,0ffh			; load interrupt-vector register
		ld      i,a			; with 0ffh
		im      2			; enable interrupt mode 2 (vectored)

		call    0f5fch
		call    0f4c9h
		db	13, 10, "RAMTEST OK"
		db	13, 10, "CTC OK"
		db	0
						
		ld      a,4fh			; select drive 1-4, Motor off, side 0, B/S=1, DD
		out     (30h),a         	   
						
		ld      d, a			; d = 4fh
		ld      b, 10			; step 5 times
stepin:	
		ld      a, 4bh			; 4b = 0100 1011 = step-in 
		call    0f36bh			; write A to FDC command and wait
		djnz    stepin          	    
	
		call    0f4c9h
		db	13, 10, "STEP IN OK"
		db	0

	
		ld      b, 64h			; seek track 00 for all 4 drives
outloop1:	ld      a, d			; select all drives
		out     (30h),a         	   
		ex      (sp),hl			; ???
		ex      (sp),hl			; ???
		ld      a, 6bh			; step out
		call    0f36bh			; write A to FDC command and wait
						
		ld      e, 01h          	    
outloop:	ld      a, e            	    
		or      40h     	
		out     (30h), a		; select one drive
		ex      (sp), hl        	    
		ex      (sp), hl        	    
		call    0f391h			; stop command, get status
		bit     2, a            	    
		jr      z, excldrv		; bit not set, not at track 00
		ld      a, e			; drive at track 00
		cpl     			; exclude drive from seeking
		and     d               	   
		ld      d, a            	    
excldrv:	
		sla     e               	   
		bit     4, e			  
		jr      z, outloop		; status checked for all 4 drives?
		djnz    outloop1		; step out again
							
		call    0f068h			; deselect floppies and seek current track?
		
		ld      hl, 0ff5eh		; set bit for each connected floppy?
		ld      bc, 0010h       	    
		ld      a, 04h          	    
nextdrv:	rr      d               	   
		jr      c, noset        	   
		set     6, (hl)         	    
noset:		add     hl, bc          	    
		dec     a               	   
		jr      nz, nextdrv     	      
						
		ld      sp, 0c100h		; set stack to 0c100h

		call    0f4c9h
		db	13, 10, "TRACK 00 OK"
		db	13, 10
		db	0
			
;--------------------------------------------------
; Main entry after startup from ROM
;--------------------------------------------------
		ld      a,01h		; executed after startup
		out     (52h),a		; turn off ROM
        
       
;		ld      a,47h	
;		out     (80h),a	
;		xor     a        
;		out     (80h),a
;loop:	
;		in	a, (80h)
;		call	printhex
;		jr	loop
		
read2byte:		
		ld	a, '.'
		call	conout
		ld      hl,0c2feh          
		di                         
		call    0f6d9h			; read 2 atari bytes
;		call	readsio
		ei                     		   
		jr      nc, read2byte  		; nothing read, read again

		ld	hl, 0c2feh
		ld	a, (hl)
		call	printhex
		inc	hl
		ld	a, (hl)
		call	printhex		

		jp      0f3deh
		jp	cpm
		
;outtest:	ld	a, 0
;		out	(50h), a
;		call	time
;		ld	a, 1
;		out	(50h), a
;		call	time
;		jr	outtest
	


		ld      hl,(0c2feh)		; load hl with bytes read
		ld      de,80e6h       		   
		or      a			; clear carry
		sbc     hl,de          		   
		;jp      z,0f3deh		; 080e6h read?
		jp      0f3deh			; cpm 080e6h read?
						
		ld      a,03h			; no
		ld      (0ff33h),a		; store 03h ff30h (03h = inc bc)
		ld      a,38h			; store 38h to f188 (038h = jr c, d) 
		ld      (0f188h),a     		   
		in      a,(50h)			; test bit 3 of RS232 (jumper, should be 1) 
		bit     3,a            		   
		jr      nz, skip       		; 
		ld      a,0ffh			; if zero, store ffh (= rst 38h)
		ld      (0f823h),a		; to f823h
skip:		
		ld      hl,0f7e1h       		  
		ld      (0f019h),hl		; f7e1h points to RET
		ld      de,(3019h)
		or      a
		sbc     hl,de
		jr      z, mainloop          	; (+0ch)
		
		ld      hl,0000h
		ld      (0ff4bh),hl
		ld      hl,0bfffh
		ld      (0ff4dh),hl
		


;--------------------------------------------------
; Looks like a main loop
;--------------------------------------------------
mainloop:
		ld	a, '1'
		call	conout		
		call    f8d1	;0f8d1h		;output to printer?

;		jp	printmenu
		
		ld	a, '2'
		call	conout
		ld      hl,(0ff3ah)		;contains f7be, then f7e2
		call	space
		call	printhl
		call	space
		call    jmphl			;call (ff3a)
		
		ld	a, '3'
		call	conout
		ld      hl,(0ff3ch)		;f7e1 (RET)
		call	printhl
		call    jmphl			;call (ff3c)
		jr      mainloop       	   	; (-11h)

jmphl:		jp      (hl)

f7be:
		ld	a, '4'
		call	conout
		in      a,(70h)		;in SIO
		and     8ah
		cp      8ah
		ret     nz
	
		ld	a, '5'
		call	conout

		di      
		xor     a
		ld      (0ff55h),a	;select 0=CMD or 1=SIO
		out     (57h),a
		ld      a,0d7h
		out     (80h),a		;program CTC
		ld      a,01h
		out     (80h),a		;counter
		ld      hl,0f699h
		ld      (0ff10h),hl	;set CTC interrupt vector
		ei      
		ld      hl,0f7e2h
		ld      (0ff3ah),hl
		ret     


f8d1:		ld      hl,(0ff4fh)	;test ff4f if zero
		ld      a,h
		call	printhex
		ld	a, l
		call	printhex
		ld	a, h
		or      l
		ret     z		;yes, return
		
		call    0f015h		;call reader (IN printer)
		ret     nz
		
		ld      hl,(0ff53h)
		call    0f8f1h		;compute new value (0 or hl+1)
		ld      (0ff53h),de
		ld      c,(hl)		;output (hl) to printer
		call    0f012h		;call PUNCH
		ld      hl,(0ff4fh)	;decrement value in ff4f/50
		dec     hl
		ld      (0ff4fh),hl
		ret    

cpm:
		ld      a,01h
		out     (52h),a
		ld	a, 'A'
		call	conout
		call    0f5fch
		ld	a, 'B'
		call	conout
cpm1:		call    0f4c9h
		db	13, 10, "SALLY1", 0
		jp	cpm1
		
		
;--------------------------------------------------
; read SIO until HL = 0C300h
;--------------------------------------------------
readsio:
		ld      de,0aaah
		ld      bc,0000h
		jr      startbit
startbitok:
		ld      a,c
		add     a,b
		adc     a,00h
		ld      c,a
		ex      (sp),hl
		ex      (sp),hl
		ex      (sp),hl
		ex      (sp),hl
		ld      b,08h
bitloop:
		ld      a,0bh
		ld      a,0bh
		nop     
bittime:
		dec     a
		jp      nz,bittime
		in      a,(70h)
		rla     
		rr      d
		djnz    bitloop            ; (-10h)
		ld      b,d
		ld      (hl),d
		inc     hl
		ld      a,h
		cp      0c3h
		ccf     
		ret     c			;fall through

startbit:
		ld      a,47h
		out     (80h),a
		xor     a
		out     (80h),a
		ld      de,01a1h
startloop:
		in      a,(80h)
		or      a
		jr      nz, startbitok         ; (-32h)
;		ret	nz
		dec     de
		ld      a,d
		or      e
		jr      nz, startloop         ; (-0ah)
		ret     


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

vars:
		db 0ffh    		;ff20	0efc ff        
		db 0ffh    		;ff21	0efd ff        
		db 0ffh    		;ff22	0efe ff        
		db 0ffh    		;ff23	0eff ff        
		db 00h    		;ff24	0f00 00        
		db 00h    		;ff25	0f01 00        
		db 00h    		;ff26	0f02 00        
		db 00h    		;ff27	0f03 00        
		db 10h,10h  		;ff28	0f04 1010      
		db 10h,10h  		;ff2a	0f06 1010      
		db 00h    		;ff2c	0f08 00        
		db 0ffh    		;ff2d	0f09 ff        
		db 01h,00h,00h		;ff2e	0f0a 010000    
		db 00h    		;ff31	0f0d 00        
		db 32h,0ah,00h		;ff32	0f0e 320a00    
		db 00h    		;ff35	0f11 00        
		db 00h    		;ff36	0f12 00        
		db 00h    		;ff37	0f13 00        
		db 21h,0f8h,0beh	;ff38	0f14 21f8be    		;ff3a f7be
		db 0f7h    		;ff3b	0f17 f7        
		db 0e1h    		;ff3c	0f18 e1        
		db 0f7h    		;ff3d	0f19 f7        
		db 002h    		;ff3e	0f1a 02        
		db 00dh    		;ff3f	0f1b 0d        
		db 00ah    		;ff40	0f1c 0a        
		db 000h    		;ff41	0f1d 00        
		db 000h    		;ff42	0f1e 00        
		db 000h    		;ff43	0f1f 00        
		db 000h    		;ff44	0f20 00        
		db 03ch    		;ff45	0f21 3c        
		db 000h    		;ff46	0f22 00        
		db 080h    		;ff47	0f23 80        
		db 000h    		;ff48	0f24 00        
		db 0b7h    		;ff49	0f25 b7        
		db 0fbh    		;ff4a	0f26 fb        
		db 000h    		;ff4b	0f27 00        
		db 0c5h    		;ff4c	0f28 c5        
		db 0ffh    		;ff4d	0f29 ff        
		db 00fh    		;ff4e	0f2a 0f        

sallycode:

		include "C:\github\Sally-1\SALLY-F000-conv.asm"
		include	"sallytest.asm"



		im	1			;interrup mode 1 = jp @ 038h
		
		ld	a, 80h			;OP7 = HIGH, deactivate RAM
		out	(OPRES), a

		ld	HL, 0			;copy ROM to RAM from
		ld	DE, 0			;to
		ld	BC, 1000h		;length, 4KB
		ldir
		
		ld	HL, 01200h		;copy ROM to RAM from $1200
		ld	DE, 0F200h		;to $F200 (CP/M Bios)
		ld	BC, 0e00h		;length, 14 pages
		ldir
		
		ld	(VARS + addr), BC	;set addr to zero
		
		ld	SP, VARS		;load stack-pointer
				
		ld	IX, VARS
		ld	(IX + echo), 1		;echo on
		ld	(IX + xonxoff), 0	;xonxoff off
	
		ld	a, $4A			;RX+TX off and
		out	(COMMA),a		;RESET ERROR
		out	(COMMB),a
	
		ld	a, $30			;RESET TRANS
		out	(COMMA),a	
		out	(COMMB),a	
		
		ld	a, $20			;RESET RECV
		out	(COMMA),a	
		out	(COMMB),a	
		
		ld	a, $10			;RESET to MODE REG1
		out	(COMMA),a	
		out	(COMMB),a	
		
		ld	a, $E0			;BRG set 2 and timer = X1/CLK
		out	(AUXCTRL),a
	
		ld	a, 0			;load timer with
		out	(CNTMSB),a		;	
		ld	a, 2			;57600 BAUD
		out	(CNTLSB),a	
	
;		in	a, (COMMA)		;Switch to test baudrates
		
		ld	a, $66			;115200 BAUD
		out	(CLOCKA),a	
;		ld	a, $66			;
		out	(CLOCKB),a	

			
		ld	a, $13			;no RTS handshake + 8bits no parity
		out	(MODEA),a			
		out	(MODEB),a	
		
		ld	a, $07			;no CTS handshake + 1 stopbit
		out	(MODEA),a	
		out	(MODEB),a	
		
		ld	a, 0			;OP2-7 output
		out	(OPCTRL),a	
		
;		ld	a, %11111111		;out = low; inverting!
;		out	(OPSET),a
	
;		ld	a, %10101010
;		out	(OPRES),a
		
		ld	a, 0			;IRQS AUS
		out	(IMR),a
		
		ld	a, 5			;RX+TX AN
		out	(COMMA),a
		out	(COMMB),a
		
		
		ld	a, 080h			;OP7 = LOW, activate RAM
		out	(OPSET), a	
			
			
		ld	c, 32			;output space
		ld	b, 0			;test how long it takes to send
		call	conout
wait:		in	a, (STATA)
		inc	b
		and	4
		jr	Z, wait

		ld	a, b			;if b < 10
		cp	10			;test baudrate is already acrivated
		jr	C, printmenu
		in	a, (COMMA)		;switch to test baudrates

;--------------------------------------------------------------
; print menu
; print prompt
; read upper key
; check if key is found in menukey
; read jmp-address and jump to subroutine
;--------------------------------------------------------------
printmenu:
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


vt102:		in	a, (STATA)
		and	a, 1
		jr	Z, vt102a
		in	a, (RECA)
		call	serout
vt102a:
		in	a, (STATB)
		and	a, 1
		jr	Z, vt102
		in	a, (RECB)
		ld	c, a
		call	conout
		jp	vt102

;--------------------------------------------------------------
; open a diskfile (and close if already assigned)
;--------------------------------------------------------------
opendisk:	
		call	getDiskno
		ret	C

		ld	c, a
		call	conout
		
		sub	a, '0'
		ld	b, a
		ld	a, 'O'
		call	serout
		ld	a, b
		call	serout
		call	serout
		call	serout
		
		call	serintime
		ret	C
		cp	'A'
		ret	NZ

		call	getfilename
		ret
		
;--------------------------------------------------------------
; close a diskfile
;--------------------------------------------------------------
closedisk:	
		call	getDiskno
		ret	C
		
		ld	c, a
		call	conout

		sub	a, '0'
		ld	b, a
		ld	a, 'C'
		call	serout
		ld	a, b
		call	serout
		call	serout
		call	serout
		
		call	serintime
		ret
		

;--------------------------------------------------------------
; enter disk number (0-9)
;--------------------------------------------------------------
getDiskno:
		ld	HL, disktext
		call	printstr
		call	conin
		cp	'0'
		ret	C
		cp	'9'+1
		ccf
		ret

;--------------------------------------------------------------
; enter text (filename) delimited by CR and send to SER:
;--------------------------------------------------------------
getfilename:	ld	HL, filetext
		call	printstr
getfilename1:
		call	conin
		call	serout
		ld	c, a
		call	conout
		cp	13
		jr	NZ, getfilename1
		ret
		
;--------------------------------------------------------------
; jump to CP/M
;--------------------------------------------------------------
cpm:
		jp	0F200h
;--------------------------------------------------------------
; jump to printmenu
;--------------------------------------------------------------
questionmark:
		pop	BC
		jp	printmenu

;--------------------------------------------------------------
; exit from monitor
;--------------------------------------------------------------
;exit:		pop	BC
;		ld	SP, (VARS + oldstack)
;		ret


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
; change a byte in (addr)
;--------------------------------------------------------------
changebyte:
		ld	HL, (VARS + addr)
		ld	a, (HL)
		call	printhex
		ld	c, ':'
		call	conout
		call	gethexbyte
		ld	(HL), a
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
		
		
		ld	c, '|'
		call	conout
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
		ld	c, a
		call	conout
		djnz	dumpmem5
		
		ld	c, '|'
		call	conout
		
		call	newline
		ld	(VARS + addr), hl
		dec	d
		jr	NZ, dumpline
		ret
	
	
;--------------------------------------------------------------
; print zero-terminated string via conout and character in C
; uses A, E
;--------------------------------------------------------------
printaddr:
		ld	a, (VARS + addr + 1)
		call	printhex
		ld	a, (VARS + addr)
		call	printhex
		jp	conout


;--------------------------------------------------------------
; download an Intel-Hex file
; uses A, B, HL, E
;--------------------------------------------------------------
download:	xor	a
		ld	(VARS + echo), a	;echo off
		ld	(VARS + sum), a		;sum = 0
		ld	HL, downtext		;print "download..."
		call	printstr
download2:	
		call	conin			;wait for ':'
		cp	a, ':'
		jr	NZ, download2
		
		call	gethexbyte		;# of bytes to read
		ld	b, a			;in b
		call	gethexbyte		;address high
		ld	h, a
		call	gethexbyte		;address low 
		ld	l, a
		call	gethexbyte		;record-type
		or	a
		jr	NZ, downend
	
download1:
		call	gethexbyte		;get byte to store
		
		ld	(HL), a			;store
		inc	HL			;increment address
		djnz	download1		;loop
		
		call	gethexbyte
		ld	a, (VARS + sum)
		or	a
		jr	NZ, downerror
	
		jr	download2
	
downend:
		call	gethexbyte
		ld	HL, downendtext
downend1:
		call	printstr
		ld	(IX + echo), 1	;echo on
		ret
	
downerror:
		ld	HL, errortext
		jr	downend1


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
		ld	c, a
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
		ld	c, a
		call	conout
		cp	CR
		jr	NZ, printstr2
		ld	c, LF
		call	conout
		jr	printstr2
printstr1:
		pop	BC
		ret
	
;--------------------------------------------------------------
; get a character in A from rs232 (1)
; 
;--------------------------------------------------------------
chrin:
		in	a, (STATA)
		and	a, 1
		jr	Z, chrin
		in	a, (RECA)
		ret

;chrin1:
;		in	a, (STATB)
;		and	a, 1
;		jr	Z, chrin
;		in	a, (RECB)
;		ret
		
;--------------------------------------------------------------
; output a character in C over rs232 (1)
; 
;--------------------------------------------------------------
chrout:
		push	AF
chrout1:	in	a, (STATA)
		and	a, 4
		jr	Z, chrout1
		ld	a, c
		out	(TRANSA), a
		pop	AF
		ret
		
;--------------------------------------------------------------
; get a character in A from rs232 (2)
; 
;--------------------------------------------------------------
serintime:
		ld	BC, 0
serintime2:	in	a, (STATB)
		and	a, 1
		jr	NZ, serintime1		;byte received?
		djnz	b, serintime2		;no, decrement b and try again
		dec	c
		jr	NZ, serintime2
		ccf				;set carry ('and' clears carry)
		ret
serintime1:	in	a, (RECB)
		ret
		
;--------------------------------------------------------------
; get a character in A from rs232 (2)
; 
;--------------------------------------------------------------
serin:
		in	a, (STATB)
		and	a, 1
		jr	Z, serin
		in	a, (RECB)
		ret

;--------------------------------------------------------------
; output a character in A over rs232 (1)
; 
;--------------------------------------------------------------
serout:
		push	AF

;		in	a, (STATB)
;		and	a, 1
;		jr	Z, serout1
;		in	a, (RECB)
;		cp	C_XOFF
;		jr	NZ, serout1
;		
;serout2:	in	a, (STATB)
;		and	a, 1
;		jr	Z, serout2
;		in	a, (RECB)
;		cp	C_XON
;		jr	NZ, serout2

serout1:	in	a, (STATB)
		and	a, 4
		jr	Z, serout1
		pop	AF
		out	(TRANSB), a
		ret	
		
menukey:
		DB	13
		DB	"?CDEFGLMNOPTV"

menutab:	DW	questionmark
		DW	changebyte
		DW	download
		DW	closedisk
		DW	fillmem
		DW	goto
		DW	disass
		DW	dumpmem
		DW	newaddress
		DW	opendisk
		DW	cpm
		DW	transfer
		DW	vt102
;		DW	exit
	
menutext:
		DB	32, 27, "[m", CR
		DB	"*************************************************", CR
		DB	"***  Z80 Mini-Monitor  (c) '22  by ", 27, "[1mR. Scholz", 27,"[m  ***", CR
		DB	"*************************************************", CR
		DB	"? - This help", CR
		DB	"C - Change byte", CR
		DB	"D - Download Intel Hex file", CR
		DB	"E - Close Disk", CR
		DB	"F - Fill memory", CR
		DB	"G - Goto address", CR
		DB	"L - Disassemble", CR
		DB	"M - Memory dump", CR
		DB	"N - New address", CR
		DB	"O - Open Disk", CR
		DB	"P - CP/M", CR
		DB	"T - Transfer memory", CR
		DB	"V - VT102 test", CR
;		DB	"X - eXit", CR
		DB	0

downtext:	DB	"downloading...", CR, 0
downendtext:	DB	"finished.", CR, 0
addrtext:	DB	"address:", 0
errortext:	DB	"error!", 0
transtext:	DB	"transfer from:", 0
lentext:	DB	" len:", 0
totext:		DB	" to:", 0
filltext:	DB	"fill from:", 0
withtext:	DB	" with:", 0
disktext:	DB	"enter disk number (0-9):",0
filetext:	DB	CR, "filename:",0

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
		push    BC
		ld      c, a
		call    conout
		pop     BC
		ret

newline:
		push    BC
		ld      c, CR
		call    conout
		ld      c, LF
		call    conout
		pop     BC
		ret

space:
		push    BC
		ld      c, ' '
		call    conout
		pop     BC
		ret

getupper:
		call	conin
		cp	'a'
		ret	C
		sub	32
		ret

conout:		equ	chrout
conin:		equ	chrin


		include "disz80.asm"
