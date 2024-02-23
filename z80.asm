	
CR:		equ	0dh
LF:		equ	0ah
C_XON		equ	17
C_XOFF		equ	19


VARS		equ	$ef00			;stack grows downwards from this address
sum:		equ	0
addr:		equ	1
echo:		equ	3			;0 = off, 1 = on
xonxoff		equ	4			;0 = transmit, 1 = stop

TXD		equ	051h

;

		ORG     0000h
		
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
					
;		ld      hl, 0			; copy rom to ram
;		ld      de, 0			
;		ld      bc, 02000h        	   
;		ldir                    	   
;		ld      a, 01h
;		out     (52h), a		
		
		ld      hl, sallycode		; copy BIOS from $00b9 to $f000
		ld      de, 0f000h		; length efc
		ld      bc, 0efch        	   
		ldir                    	   
		ld      hl, sallycode + 0fb5h - 0b9h ; copy from fb5 to $ff20
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
						
		ld      a,4fh			; select drive 1-4, Motor off, side 0, B/S=1, DD
		out     (30h),a         	   
						
		ld      d, a			; d = 4fh
		ld      b, 10			; step 5 times
stepin:	
		ld      a, 4bh			; 4b = 0100 1011 = step-in 
		call    0f36bh			; write A to FDC command and wait
		djnz    stepin          	    
						
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
		out     (30h), a		; selct one drive
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
			
;tloop:		in	a, (70h)
;		rlca
;		and	1
;		add	65
;		call	conout
;		jp	tloop
;	
;		ld      a, 01h			; ROM SW
;		out     (52h), a

;		ld      a,47h			; CH0 noint+counter+pre16+falling autocnt+timeconst+reset+ctrl
;		out     (80h),a			;        	 4              	7
;;		xor     a               	   
;		out     (80h),a			; counter init value 0
;		
;waits:		in      a,(80h)			; counter zero?
;		call	printhex
;		jr	waits


	
;get2siol:	ld      hl, 0c2feh
;		call    get2sio
;		push	af
;		ld	a, '.'
;		call	conout
;		pop	af
;		jr      nc, get2siol
;
;		ld	hl, (0c2feh)
;		ld	a, l
;		call	printhex
;		ld	a, h
;		call	printhex	
;		
;		jp	printmenu

		jp      0f762h			; jump to code in DRAM
;
;get2sio:		
;		ld      de,0aaah		; read atari ser 19200 Baud
;		ld      bc,0000h
;		jr      getstartbit
;gotstartbit:
;		ld      a, c			; checksum in c
;		add     a, b
;		adc     a, 00h
;		ld      c, a
;		ex      (sp), hl
;		ex      (sp), hl
;		ex      (sp), hl
;		ex      (sp), hl
;		ld      b, 08h			; 7
;loopbit:	
;		ld      a, 0bh			; 7
;		ld      a, 0bh			; 7
;		nop     				; 4
;loop19200:	dec     a			; 4	11*14
;		jp      nz, loop19200		; 10
;		in      a,(70h)			; 11
;		rla     			; 4
;		rr      d			; 8
;		djnz    loopbit         	; 13	208
;		ld      b, d
;;		ld	a, d
;;		call	printhex
;		ld      (hl), d
;		inc     hl
;		ld      a, h
;		cp      0c3h
;		ccf     
;		ret     c			; 2bytes read and carry set
;
;getstartbit:    	
;		ld      a,47h			; CH0 noint+counter+pre16+falling autocnt+timeconst+reset+ctrl
;		out     (80h),a			;        	 4              	7
;		xor     a               	   
;		out     (80h),a			; counter init value 0
;		ld      de,01a1h        	   
;waitstart:	
;		in      a,(80h)			; counter zero?
;		or      a                  
;		jr      nz, gotstartbit         ; start-bit
;		
;		dec     de                 
;		ld      a, d                
;		or      e                  
;		jr      nz, waitstart
;		ret     			; return carry clear, zero
;--------------------------------------------------
; 11 times port:value
;--------------------------------------------------
portval:	db	050h, 001h
		db	051h, 001h
		db	080h, 003h
		db 	080h, 010h
		db	081h, 007h
		db	081h, 001h
		db	082h, 003h
		db	083h, 003h
		db	057h, 001h
		db	030h, 000h
		db	040h, 0d0h

sallycode:

		include "C:\github\Sally-1\SALLY-F000-conv.asm"
		include	"sallytest.asm"
