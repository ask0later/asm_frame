.model tiny
.code
.186
org 100h

include codes.asm

locals @@


;----------------------------------------------------
START:
		jmp Main
		
;----------------------------------------------------

ControlStrArray_1 db 0d5h, 0cdh, 0b8h, 0b3h, 00h, 0b3h, 0d4h, 0cdh, 0beh

;ControlStrArray_2 db 05h, 0dh, 08h, 03h, 00h, 03h, 04h, 0dh, 0eh

;----------------------------------------------------
; Skips gaps in memory es:[di] by adding register di
; Entry: 
;		 ds - data segment
;	 	 si - offset ds
; Assumes: 
; Destr: si, al
;---------------------------------------------------
SkipSpaces	proc
			mov al, 20h			; = ASCII code space
			
			@@loop:
				cmp al, ds:[si]
				jne @@exit
				inc si
				loop @@loop

			@@exit:

			ret
			endp
;---------------------------------------------------



;---------------------------------------------------
; Parses a color and puts it 
; into RAM with address di register
; Entry: 
;		 ds - extra segment
;	 	 si - offset es
; Assumes: 
; Destr: ax, bx, di, si
;---------------------------------------------------
ParseColor	proc
			
			xor ax, ax
			xor bx, bx

			mov al, ds:[si]
			inc si
			dec cx

			
			cmp al, 'a'
			ja @@letter_1
			sub al, '0'
			jmp @@digit_1
			@@letter_1:
			sub al, 'a'
			add al, 10d					
			@@digit_1:

			
			shl al, 1					;
			shl al, 1					;
			shl al, 1					;
			shl al, 1					; ax = ax * 16 

			
			mov bl, ds:[si]				;

			inc si
			dec cx
			
			cmp bl, 'a'
			ja @@letter_2
			sub bl, '0'
			jmp @@digit_2
			@@letter_2:
			sub bl, 'a'
			add bl, 10d					
			@@digit_2:
			
			add al, bl

			mov ds:[di], al  			; into RAM 

			ret
			endp
;---------------------------------------------------

;---------------------------------------------------
; Parses a number and puts it 
; into RAM with address di register
; Entry: 
;		 ds - extra segment
;	 	 si - offset es
; Assumes: 
; Destr: ax, bx, di, si
;---------------------------------------------------
ParseNumber	proc
			
			xor ax, ax
			xor bx, bx

			mov al, ds:[si]
			sub al, '0'					; get real digit

			inc si
			dec cx

			shl al, 1					;
			mov bl, al					;
										;
			shl al, 1					;
			shl al, 1					;
										;
			add al, bl					; ax = ax * 10

			mov bl, ds:[si]				;
			sub bl, '0'					; get real digit

			add al, bl
			inc si
			dec cx

			mov ds:[di], al  			; into RAM 

			ret
			endp
;---------------------------------------------------



;---------------------------------------------------
; Parses the command line and sets the frame length, 
; frame height, frame attribute and frame style 
; Entry: 
;
; Assumes: ds:[81h] - command line start address
;		   ds:[80h] - address the number 
;          of entered characters in the command line
;
; Destr:
;----------------------------------------------------
ParseCommandLine	proc
					xor cx, cx
					xor ax, ax

					mov byte ptr cl, ds:[0080h]
					mov si, offset [81h]

					call SkipSpaces
					mov di, LenghtAddress
					call ParseNumber

					call SkipSpaces
					mov di, HeightAddress
					call ParseNumber

					call SkipSpaces
					mov di, ColorAddress
					call ParseColor

					ret
					endp
;----------------------------------------------------





;----------------------------------------------------
; Writes a string of n identical characters to video memory
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds
;		 bx - frame length
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, di, cx
;----------------------------------------------------
PrintLine	proc
			nop
			
			mov al, byte ptr ds:[si]			;
			inc si

			stosw								; mov ptr word es:[di], ax

			mov cx, bx
			dec cx
			dec cx

			mov al, byte ptr ds:[si]			;
			inc si

			@@loop:
			stosw								; mov ptr word es:[di], ax
			loop @@loop

			mov al, byte ptr ds:[si]			;
			inc si

			stosw								; mov ptr word es:[di], ax

			dec si
			dec si
			dec si

			nop
			endp
;----------------------------------------------------

;----------------------------------------------------
; Сhanges the offset to the address of new line
; Entry: di - offset to the beginning of video memory
;		 bx - frame length 
; Assumes: number of characters 
; that fit in a line = LineLength = 80
; Destr: di
;----------------------------------------------------
NewLine		proc
			nop 
			
			add di, LineLength
			sub di, bx

			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; Writes a frame
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds
;		 bx - frame length
;		 dx - frame height
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, cx, di, si
;----------------------------------------------------
PrintFrame	proc
			
			xor bx, bx
			xor dx, dx
			xor ax, ax
			xor di, di

			mov bl, byte ptr ds:[LenghtAddress]
			mov dl, byte ptr ds:[HeightAddress]
			mov ah, byte ptr ds:[ColorAddress]

			call PrintLine
			call NewLine

			inc si
			inc si
			inc si

			mov cx, dx
			dec cx
			dec cx

			@@loop:
			push cx

			call PrintLine
			call NewLine
			
			pop cx
			loop @@loop

			inc si
			inc si
			inc si

			call PrintLine
			call NewLine

			inc si
			inc si
			inc si
		
			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; writes a shadow on the frame 
; Entry: bx - offset to the beginning of video memory
; Assumes: number of characters 
; that fit in a line = LineLength = 80
; Destr: ax, bx, cx, dx
;----------------------------------------------------
PrintShadow	proc
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

		xor di, di
		xor si, si

		xor ax, ax

		call ParseCommandLine

;		xor dl, dl
;		mov dl, al
;		mov ah, 02h
;		int 21h

		mov si, offset ControlStrArray_1

		call PrintFrame


		mov ax, 4c01h
		int 21h
		
;----------------------------------------------------

end		START
