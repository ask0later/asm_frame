.model tiny
.code
.186
org 100h

include codes.asm


;----------------------------------------------------
START:
		jmp Main
		
;----------------------------------------------------


;----------------------------------------------------
; Writes a symbol to video memory
; Entry: ah - color attribute
;	 al - symbol
;	 bx - offset to video memory
; Assumes: es - VideoMemAddress (0b800h)
; Destr:   
;----------------------------------------------------
PrintSymbol	proc
		nop

		mov byte ptr es:[bx], al	; even byte
		mov byte ptr es:[bx + 1], ah	; odd byte
		ret
		
		nop
		endp
;----------------------------------------------------



;----------------------------------------------------
; Writes a string of n identical characters to video memory
; Entry: ah - color attribute
;	 al - symbol
;	 bx - offset to the beginning of video memory
;	 cx - number of characters
; Assumes: es - VideoMemAddress (0b800h)
; Destr: bx, dx
;----------------------------------------------------
PrintLine	proc
		nop
		
		xor dx, dx		; dx = 0
		
		start_loop_1:		
			cmp dx, cx
			jge exit_loop_1
			
			call PrintSymbol
			inc dx
			inc bx
			inc bx
			jmp start_loop_1
		exit_loop_1:
		ret
		
		nop
		endp
;----------------------------------------------------

;----------------------------------------------------
; Сhanges the offset to the address of the next 
; beginning of the line
;
; Entry: bx - offset to the beginning of video memory
; Assumes: number of characters 
; that fit in a line = LineLength = 80
; frame length = FrameLength = 30
; Destr: bx, dx
;----------------------------------------------------
ChangeOffset	proc
		nop
		
		add bx, ByteWord * LineLength		; = 2 * 80
		sub bx, ByteWord * FrameLength		; = 2 * 30
		
		nop
		ret
		
		endp
;----------------------------------------------------


;----------------------------------------------------
; writes a frame
; Entry: 
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, bx, cx, dx, di
;----------------------------------------------------
PrintFrame	proc
		nop
		
		mov ah, WhiteOnRed		; = 01001111b
		
		mov al, UpLFrame		
		call PrintSymbol		; upper left character
		
		inc bx
		inc bx
		
		mov al, HorFrame		
		mov cx, 10d 			; = (30 - 8) / 2
		call PrintLine			; top line of the frame

		call PrintTitle
		mov ah, WhiteOnRed		; = 01001111b

		mov al, HorFrame		
		mov cx, 10d 			; = (30 - 8) / 2
		call PrintLine			; top line of the frame
		
		mov al, UpRFrame
		call PrintSymbol		; upper right character
		
		inc bx
		inc bx
		
		call ChangeOffset
;-----------------------------------------------------		
		
		xor di, di				; di = 0
			
		start_loop_2:	
			cmp di, FrameHeight 	 ; = 10 - 2 
			jge exit_loop_2
			
			inc di
			
			mov al, VertFrame		
			call PrintSymbol	 ; middle left character
			
			inc bx
			inc bx
			
			xor al, al

			mov cx, FrameLength - 2d  ; = 30 - 2
			call PrintLine		 ; middle line of the frame
			
			mov al, VertFrame
			call PrintSymbol	; middle right character
			
			inc bx
			inc bx
			
			call ChangeOffset
			
			jmp start_loop_2
		exit_loop_2:
		
		
		
;------------------------------------------------------
		
		mov al, LowLFrame		
		call PrintSymbol		; lower left character
		inc bx
		inc bx
		
		mov al, HorFrame		
		mov cx, FrameLength - 2d		; = 30 - 2
		call PrintLine			; low line of the frame
		
		mov al, LowRFrame
		call PrintSymbol		; lower right character
		inc bx
		inc bx
		
		call ChangeOffset
		
		ret
		
		nop
		endp
;----------------------------------------------------


;----------------------------------------------------
; writes the title of the frame
; Entry: bx - offset to the beginning of video memory
; Assumes: TitleLength = 8
; Destr: ax, bx
;----------------------------------------------------
PrintTitle	proc
		nop 

		mov ah, MagentaOnRed		; = 01001101b 
		mov al, HeartCode
		call PrintSymbol
		inc bx
		inc bx

		mov al, k_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, a_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, r_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, i_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, n_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, a_code
		call PrintSymbol
		inc bx
		inc bx

		mov al, HeartCode
		call PrintSymbol
		inc bx
		inc bx

		ret
		nop

		endp
;---------------------------------------------------


;----------------------------------------------------
; writes a shadow on the frame 
; Entry: bx - offset to the beginning of video memory
; Assumes: number of characters 
; that fit in a line = LineLength = 80
; FrameLength = 30
; FrameHeight = 10
; Destr: ax, bx, cx, dx
;----------------------------------------------------
PrintShadow	proc
nop 

		mov ah, WhiteOnGrey 			; = /////10001000b 
		xor al, al 				; al = 0 
		xor bx, bx 				; bx = 0
		xor dx, dx				; dx = 0
		
		

		add bx, FrameLength * ByteWord 		; = 30 * 2
		add bx, LineLength * ByteWord 		; = 80 * 2
		
		mov al, UpRFrame
		call PrintSymbol
		
		add bx, LineLength * ByteWord 		; = 80 * 2
		
		mov al, VertFrame
		start_loop_4:		
			cmp dx, FrameHeight - 2d	; = 10 - 2
			jg exit_loop_4
			
			inc dx
			call PrintSymbol
			add bx, LineLength * ByteWord 	; = 80 * 2

			jmp start_loop_4
		exit_loop_4:

		call PrintSymbol
		call ChangeOffset
		inc bx
		inc bx
		
		mov al, LowLFrame
		call PrintSymbol
		
		mov al, HorFrame
		add bx, ByteWord 			; = 80 * 2
		mov cx, FrameLength - 2d 		; = 30 - 2
		
		call PrintLine
		
		mov al, LowRFrame
		call PrintSymbol
		
		ret
		nop

		endp

;----------------------------------------------------


;----------------------------------------------------
; Defines the initial data of the registers
; (Main Procedure)
; Entry: 
; Assumes:
; Destr: ax, bx, cx, dx, di
;----------------------------------------------------
Main:		nop
		mov bx, VideoMemAddress	; = 0b800h
		mov es, bx				; es = video mem address

		xor bx, bx 				; offset video memory
		
		
		call PrintFrame 
		call PrintShadow
		
		mov ax, 4c01h
		int 21h
		
;----------------------------------------------------

end		START
