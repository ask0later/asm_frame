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
string_1 db 'pidor', 00h, '$'
string_2 db 'pidor', 00h, '$'



;----------------------------------------------------

								; PrintSymbol	mov word ptr es:[bx], ax

;----------------------------------------------------
; Compares two arrays by byte 
; The comparison continues until n bytes are checked 
; or different bytes are encountered. 
; Entry: ds - data segment
;		 si - offset first array
;		 es - extra segment		 
;		 di - offset second array
;	 	 cx - number of bytes (characters)
;		 al - result
; Assumes:
; Destr: al, di, si, cx
;----------------------------------------------------
MyMemcmp	proc
	
			xor bx, bx
			cld

			repe cmpsb			; while((cx--) && (es:[di++] == ds:[si++]))
			
			xor al, al
			
			ja above
			
			jb below
			below:
			mov al, 0FFh
			ret

			above:
			mov al, 01h
			
			ret
			endp
;----------------------------------------------------



;----------------------------------------------------
; Copies n bytes from the source argument 
; to the destination argument 
; If the arrays overlap, 
; the result of the copy will be undefined. 
; Entry: ds - src  segment
;		 si - offset ds
;		 es - dest segment		 
;		 di - offset es
;	 	 cx - number of bytes (characters)
; Assumes:
; Destr: di, si, cx
;----------------------------------------------------
MyMemcpy	proc
	
			xor bx, bx
			cld

			rep movsb 			; while(cx--) {es:[di++] = ds:[si++]}
			
			ret
			endp
;----------------------------------------------------




;----------------------------------------------------
; Fill the array with the specified characters 
; Entry: al - symbol code
;	 	 cx - number of characters
; Assumes: es = data segment
; Destr: ax, bx, cx
;----------------------------------------------------
MyMemset	proc
	
			xor bx, bx
			cld

			loop_1:
				cmp bx, es:[di]
				je exit_1
				
				stosb  			; es:[di++] = al 
			
				loop loop_1
			exit_1:
			
			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; Searches for an character in the array 
; and returns its number in the array
; Entry: al - symbol code
; Assumes: es = data segment
; Destr: ax, bx, cx
;----------------------------------------------------
MyMemchr	proc
		
			mov bx, di
			mov cx, 0FFFFh
			
			repne scasb
			
			dec di
			
			sub di, bx
			
			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; Counts the number of characters in the string (to 0)
; 
; Entry:
; Assumes: es = data segment
; Destr: al, bx, cx, di 
;----------------------------------------------------
MyStrlen	proc
		
			xor al, al
			
			mov bx, di
			mov cx, 0FFFFh
			
			repne scasb
			
			dec di
			
			sub di, bx
			
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
		mov bx, ds
		mov es, bx			; es = ds
		
		mov di, offset string_1 		; lea di, string 
		mov si, offset string_2 		; lea di, string

		mov dx, di

		mov ah, 09h
		int 21h

		mov dx, si

		mov ah, 09h
		int 21h

		
		xor ax, ax
		xor bx, bx
		
		mov cx, 5d

		call MyMemcmp
		

						; call MyStrlen
						; mov al, 067h			; = g
						; call MyMemset
		
		
		
		mov ax, 4c01h
		int 21h
		
;----------------------------------------------------

end		START
