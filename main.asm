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
				; array with frame edge symbols
ControlStrArray db 0dah, 0c4h, 0bfh, 0b3h, 00h, 0b3h, 0c0h, 0c4h, 0d9h, 0c9h, 0cdh, 0bbh, 0bah, 00h, 0bah, 0c8h, 0cdh, 0bch, '$'

				; an array into which you can write information and not corrupt someone else's information
FreeMemory db 100 dup(0), '$'


;----------------------------------------------------
; Skips gaps in memory ds:[si] by adding register si
; Entry: 
;		 ds - data segment
;	 	 si - offset ds
; Assumes: cx decreases 
; Destr: si, al
;---------------------------------------------------
SkipSpaces	proc
			mov al, ' '				; SPACE
			
			@@loop:
				cmp al, ds:[si]
				jne @@exit
				inc si
				loop @@loop
			@@exit:

			ret
			endp
;---------------------------------------------------

;----------------------------------------------------
; Parses text from the command line 
; Places into RAM the size and address of text and title 
; Entry: 
;	 	 si - offset ds (command line)
;		 di - offset ds (free memory)
;		 [FreeMemory + TitleAddress] = size title
;		 [FreeMemory + TitleAddress + 1] = ptr title
;
;		 [FreeMemory + TextAddress]  = size text
;		 [FreeMemory + TextAddress + 1]  = ptr text
;
; Assumes: Title : text_in_frame
;		   cx decreases
; Destr: ax, di, si
;---------------------------------------------------
ParseText	proc
			xor di, di
			xor ax, ax
			
			mov di, offset FreeMemory				;
			add di, TitleAddress			
			inc di									; di = FreeMemory + TitleAddress + 1
			
			mov word ptr ds:[di], si				; [FreeMemory + TitleAddress + 1] = offset ptr title (WORD)
			
			dec di									; di = FreeMemory + TitleAddress
			push di
			xor di, di

			mov al, ':'								;
			@@loop_1:
				inc di								; characters count 
				inc si								;
				dec cx								;
				cmp al, ds:[si]						;
				jne @@loop_1						;
													; finded ':' or cx == 0
			inc si
			dec cx

			call SkipSpaces
			xor ax, ax

			mov ax, di								; ax = title size
			pop di									; di = FreeMemory + TitleAddress					

			mov byte ptr ds:[di], al 				; [FreeMemory+ TitleAddress] = title size (BYTE)

			xor dx, dx

			mov di, offset FreeMemory				;
			add di, (TextAddress)					; di = FreeMemory + TextAddress
			

			mov byte ptr ds:[di], cl				; [FreeMemory + TextAddress] = text size (BYTE)
			
			inc di

			mov word ptr ds:[di], si				; [FreeMemory + TextAddress + 1] = offset ptr text (WORD)

			ret
			endp
;---------------------------------------------------


;----------------------------------------------------
; Selects the frame style from the command line
; Puts the ptr of the style array 
; into the si register
; Entry:    
;			si - offset ds (on command line)
;			ds:[FreeMemory + StyleAddress] = ptr of style array
;
; Assumes: ds - data segment
;		   *_________ - users style
;		   01 - address of ControlStrArray
;		   02 - address of ControlStrArray + 9
;		   cx decreases
; Destr: ax, bx, si, cx, bp
;---------------------------------------------------
ParseStyle	proc

			xor bp, bp

			mov bp, si

			cmp byte ptr ds:[si], '*'
			jne @@other_style
			inc bp									; ptr first char of users style array

			add si, 10d
			sub cx, 10d								; counter, what is left
			jmp @@exit
			
			@@other_style:
				xor ax, ax
				xor bx, bx

				call ParseNumber

				mov bp, offset ControlStrArray

				mov al, byte ptr ds:[FreeMemory + StyleAddress]
				dec al								

				mov bl, al							;
				shl al, 3							;
				add al, bl							; ax = ax * 9

				add bp, ax							; first char os style array
			
			@@exit:
				mov word ptr ds:[FreeMemory + StyleAddress], bp		; ptr on style array
			

			ret
			endp
;---------------------------------------------------

;---------------------------------------------------
; Parses a color and puts it 
; into RAM with address di register
; Entry: 
;	 	 si - offset ds (command line)
; Assumes:  ds - data segment
;			cx decreases
; Destr: ax, bx, di, si
;---------------------------------------------------
ParseColor	proc
			
			xor ax, ax
			xor bx, bx

			mov al, ds:[si]				; al = char
			inc si
			dec cx
			
			cmp al, 'a'					; if (al > a)
			ja @@letter_1				; {
			sub al, '0'					; 	   al = al - 'a'
			jmp @@digit_1				; }	
			@@letter_1:					; else
			sub al, 'a'					; {
			add al, 10d					;	   al = al - '0'
			@@digit_1:					; }
			

			shl al, 4					; al = al * 16
			
			mov bl, ds:[si]				;

			inc si
			dec cx
			
			cmp bl, 'a'					; if (bl > a)
			ja @@letter_2     			; {
			sub bl, '0'					; 	   bl = bl - 'a'
			jmp @@digit_2				; }
			@@letter_2:					; else
			sub bl, 'a'					; {
			add bl, 10d					;	   bl = bl - '0'
			@@digit_2:					; }
			
			add al, bl					; al = attribute hex

			mov ds:[di + FreeMemory], al  	; into free memory

			ret
			endp
;---------------------------------------------------



;---------------------------------------------------
; Parses a number and puts it 
; into RAM with address di register
; Entry: 
;		 ds - data segment
;	 	 si - offset ds (command line)
;		 di - offset of free memory
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
			shl al, 2					;
										;
			add al, bl					; ax = ax * 10

			mov bl, ds:[si]				;
			sub bl, '0'					; get real digit

			add al, bl
			inc si
			dec cx

			mov ds:[di + FreeMemory], al  	; into free memory

			ret
			endp
;---------------------------------------------------



;---------------------------------------------------
; Parses the command line and sets the frame length, 
; frame height, frame attribute and frame style 
; in RAM = [FreeMemory]
; Entry:   
;			si - offset of start command line
;		    di - offset of start free memory
;
; Assumes: ds - data segment
;		   ds:[81h] - command line start address
;		   ds:[80h] - address the number 
;          of entered characters in the command line
;		   cx - counter with start value = number of character of com line
; Destr: ax, bx, cx, si, di 
;----------------------------------------------------
ParseCommandLine	proc

					xor cx, cx
					xor ax, ax

					mov byte ptr cl, ds:[PtrCommmandLine]	; cl = nubmer of characher on com line
					mov si, offset [PtrCommmandLine + 1h]	; si = ptr on first char on com line

					call SkipSpaces					
					mov di, LenghtAddress			; number is length
					call ParseNumber

					call SkipSpaces
					mov di, HeightAddress			; number is height
					call ParseNumber

					call SkipSpaces
					mov di, ColorAddress			; number is attribute
					call ParseColor

					call SkipSpaces
					mov di, StyleAddress			; number is style
					call ParseStyle

					call SkipSpaces					
					call ParseText					; title:text

					ret
					endp
;----------------------------------------------------



;----------------------------------------------------
; Writes a string of n identical characters to video memory
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds (offset to the beginning of style array)
;		 bx - frame length
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, di, cx
;----------------------------------------------------
PrintLine	proc
			
			mov al, byte ptr ds:[si]			; al = first symbol of style array
			inc si

			stosw								; mov ptr word es:[di], ax

			mov cx, bx							; frame length
			dec cx
			dec cx

			mov al, byte ptr ds:[si]			; al = second symbol of style array
			inc si

			@@loop:
			stosw								; mov ptr word es:[di], ax
			loop @@loop

			mov al, byte ptr ds:[si]			; al = third symbol of style array
			inc si

			stosw								; mov ptr word es:[di], ax

			dec si
			dec si
			dec si								; si = start of style array

			ret
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
			
			add di, LineLength * 2
			shl bx, 1
			sub di, bx
			shr bx, 1

			ret
			endp
;----------------------------------------------------

;----------------------------------------------------
; Puts n characters from the array into video memory 
; Entry: 
;		 di - offset to the beginning of video memory
;		 bx - number of symbols
;		 bp - offset to text
;
; Assumes: 
;		   es - VideoMemAddress (0b800h)
; that fit in a line = LineLength = 80
; Destr: AL, cx
;----------------------------------------------------
PrintTextLine	proc

				xor cx, cx

				@@loop:
					inc cx						; counter char of text
					inc cx

					mov al, byte ptr ds:[bp]	; from text ds:[bp]

					cmp al, ';'					; ';' = new line
					jne @@no_new_line

					sub di, cx
					xor cx, cx					; counter = 0
					add di, LineLength * 2		; to new line

					jmp @@new_line
					@@no_new_line:
					
					mov word ptr es:[di], ax	; into video mem

					@@new_line:

					inc di
					inc di
					dec bx
					inc bp

					cmp bx, 00h
					je @@exit
					jmp @@loop
				@@exit:

				ret
				endp
;----------------------------------------------------

;----------------------------------------------------
; Prints the text in a frame, 
; which on input was after ':'
; Entry:
;				bx - frame length
;				dx - frame height
;				di - offset to the beginning of video memory
;		 		bp - offset to text
;  Assumes:	es - VideoMemAddress (0b800h)
;
;  Destr: si, di, cx
;----------------------------------------------------
PrintText		proc

				xor si, si
				xor cx, cx

				push bx									; saves bx

				mov si, offset FreeMemory
				add si, TextAddress						; si = FreeMemory + TitleAddress				

				mov bl, byte ptr ds:[si]				; bl = text size


				add di, Paragraph						; = 10

				and di, 0fffeh							; remove the odd
				
				inc si									; bp = FreeMemory + TitleAddress + 1
				mov bp, word ptr ds:[si]				; bp = text ptr

				xor si, si
				xor cx, cx

				mov cx, dx
				shr cx, 1
				dec cx

				@@loop:									; middle of height
					dec cx
					add di, (LineLength * 2)			; 80 * 2
					cmp cx, 00h
					je @@exit
					jmp @@loop
				@@exit:
				
				call PrintTextLine

				pop bx

				ret
				endp
;----------------------------------------------------



;----------------------------------------------------
; Prints the text in a frame, 
; which on input was before ':'
; Entry:
;				bx - frame length
;				di - offset to the beginning of video memory
;		 		bp - offset to text
;  Assumes:	es - VideoMemAddress (0b800h)
;
;  Destr: si, di, cx
;----------------------------------------------------
PrintTitle		proc

				xor si, si
				xor cx, cx
				mov cx, bx

				push bx									; saves bx

				mov si, offset FreeMemory
				add si, TitleAddress					; bp = FreeMemory + TitleAddress				

				mov bl, byte ptr ds:[si]				; bl = size title

				sub cx, bx								; midlle of lenght

				add di, cx

				and di, 0fffeh							; remove the odd
				
				inc si									; bp = FreeMemory + TitleAddress + 1
				mov bp, word ptr ds:[si]				; bp = title ptr

				xor si, si

				call PrintTextLine

				pop bx

				ret
				endp
;----------------------------------------------------


;----------------------------------------------------
; Writes a frame
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds (offset to the beginning of style array)
;		 bx - frame length
;		 dx - frame height
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, cx, di, si, bp
;----------------------------------------------------
PrintFrame	proc
			
			xor bx, bx
			xor dx, dx
			xor ax, ax
			xor di, di
			xor bp, bp
			xor si, si

			mov di, FrameOffset			; = 880 = 160 * 5 + 80
			
			mov si, word ptr ds:[FreeMemory + StyleAddress]			; si = offset of style array

			mov bl, byte ptr ds:[LenghtAddress + FreeMemory]		; bl = frame length
			mov dl, byte ptr ds:[HeightAddress + FreeMemory]		; dl = frame height
			mov ah, byte ptr ds:[ColorAddress  + FreeMemory]		; ah = frame color

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

			xor di, di
			mov di, FrameOffset			; = 880 = 160 * 5 + 80 

			call PrintTitle

			xor di, di
			mov di, FrameOffset			; = 880 = 160 * 5 + 80

			call PrintText
		
			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; writes a shadow on the frame 
; Entry: di - offset to the beginning of video memory
; Assumes: number of characters 
; that fit in a line = LineLength = 80
; 		   bx - frame lenght
; 		   dx - frame height
; Destr: ax, bx, cx, dx
;----------------------------------------------------
PrintShadow	proc

		xor di, di
		xor cx, cx
		xor al, al	

		mov di, FrameOffset			; = 880 = 160 * 5 + 80

		mov ah, WhiteOnGrey 	
				
		mov cx, bx				
		shl cx, 1					; cx = lenght * 2

		add di, cx					
		add di, LineLength * 2		; next line 
		
		mov al, UpRFrame
		mov word ptr es:[di], ax
		
		xor cx, cx

		mov cx, dx
		dec cx
		dec cx

		mov al, VertFrame
		
		@@loop_1:
			add di, LineLength * 2 		; = 80 * 2
			mov word ptr es:[di], ax

			loop @@loop_1
		@@exit_1:
		

		call NewLine
		inc di
		inc di
		
		mov al, LowLFrame
		mov word ptr es:[di], ax
		inc di
		inc di
		
		mov al, HorFrame
		
		mov cx, bx 				; 
		dec cx
		dec cx

		
		@@loop_2:
			mov word ptr es:[di], ax
			inc di
			inc di

			loop @@loop_2
		@@exit_2:
		
		mov al, LowRFrame
		mov word ptr es:[di], ax

		xor di, di
		
		ret
		endp
;----------------------------------------------------


;----------------------------------------------------
; Defines the initial data of the registers
; (Main Procedure)
; Entry: 
; Assumes:
; Destr: ax, bx, cx, dx, di
;----------------------------------------------------
Main:
			mov bx, VideoMemAddress	; = 0b800h
			mov es, bx				; es = video mem address

			xor di, di
			xor si, si
			xor ax, ax

			call ParseCommandLine


			call PrintFrame
			call PrintShadow

			mov ax, 4c01h
			int 21h
		
;----------------------------------------------------

end		START
