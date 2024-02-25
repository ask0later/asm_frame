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
																		;
ControlStrArray db 0c9h, 0cdh, 0bbh, 0bah, 00h, 0bah, 0c8h, 0cdh, 0bch, '$'

RegisterName db 'AX', 'BX', 'CX', 'DX', 'SI', 'DI', 'BP', 'DS', 'ES', 'SS', 'SP', 'IP', 'CS', '$'
AddressSavesVideoMem dw 165 dup (0)

OldValueAX dw 0, '$'
OldValueSP dw 0, '$'

FrameFlag db 0




;----------------------------------------------------
; Writes a string of n identical characters to video memory
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds (offset to the beginning of style array)
;		 bx - frame length
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, di, cx, si
;----------------------------------------------------
PrintLine	proc
			
			mov al, byte ptr cs:[si]			; al = first symbol of style array
			inc si

			stosw								; mov ptr word es:[di], ax

			mov cx, bx							; frame length
			dec cx
			dec cx

			mov al, byte ptr cs:[si]			; al = second symbol of style array
			inc si

			@@loop:
			stosw								; mov ptr word es:[di], ax
			loop @@loop

			mov al, byte ptr cs:[si]			; al = third symbol of style array
			inc si

			stosw								; mov ptr word es:[di], ax

			dec si
			dec si
			dec si								; si = start of style array

			ret
			endp
;----------------------------------------------------


;----------------------------------------------------
; converts the digit to its ASCII code value (hex) 
; Entry: al - value of number
; Assumes: 
; Destr: al
;----------------------------------------------------
Converter 	proc

			cmp al, 9d
			ja @@letter
			add al, '0'
			jmp @@digit
			@@letter:
				sub al, 10d
				add al, 'a'
			@@digit:

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
; Writes a frame
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
;		 si - offset ds (offset to the beginning of style array)
;		 bx - frame length
;		 dx - frame height
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, bx, dx, cx, di, si
;----------------------------------------------------
PrintFrame		proc
			push bx
			push dx
			push si

			xor bx, bx
			xor dx, dx
			xor si, si
			
			mov si, offset ControlStrArray

			mov bx, FrameLength
			mov dx, FrameHeight 
			mov ah, WhiteOnMagenta

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

			pop bx
			pop dx
			pop si

			ret
			endp
;----------------------------------------------------

;----------------------------------------------------
; function prints hex number from bx register
; Entry: es - extra segment
;	 	 di - offset es (offset to the beginning of video memory)
;		 ds - data segment
; Assumes: es - VideoMemAddress (0b800h)
; Destr: ax, bx, dx, di
;----------------------------------------------------
PrintHexNumber	proc

				mov dx, bx

				shr bh, 4
				mov al, bh							; first high 4 bit
				call Converter
				stosw								; mov word ptr es:[di], ax; di+=2

				shl bh, 4
				sub dh, bh
				mov al, dh							; second high 4 bit
				call Converter
				stosw								; mov word ptr es:[di], ax; di+=2


				shr bl, 4
				mov al, bl							; first low 4 bit
				call Converter
				stosw								; mov word ptr es:[di], ax; di+=2

				shl bl, 4
				sub dl, bl
				mov al, dl							; second low 4 bit
				call Converter
				stosw								; mov word ptr es:[di], ax; di+=2


				ret
				endp
;----------------------------------------------------

;----------------------------------------------------
; function writes the register name and 
; its value taken from the register
; Entry: si - offset to array RegisterName 
;	 	 di - offset of extra segment
;		 
;		 
; Assumes: es - 0b800h
; Destr: ax, bx, dx, di, si, bp
;----------------------------------------------------
PrintRegister	proc

				mov al, byte ptr cs:[si]
				inc si
				stosw								; mov word ptr es:[di], ax; di+=2
				
				mov al, byte ptr cs:[si]
				inc si
				stosw								; mov word ptr es:[di], ax; di+=2
				
				mov al, ' '
				stosw								; mov word ptr es:[di], ax; di+=2

				
				mov bx, [bp]						; bx = number that will be printed 
				call PrintHexNumber					; print hex number

				ret	
				endp

;----------------------------------------------------

;----------------------------------------------------
; function writes the value of all registers in a frame
; Entry: 
;		 
;		 
; Assumes:
; Destr: ax, bx, cx, dx, di, si
;----------------------------------------------------
PrintRegInfo 	proc
			
			push bp
			mov bp, sp
			add bp, 6d					; bp = sp + 6
										; in stack (bp, ip_ret, ip_ret)

			push 0b800h					; offset to video memory
            pop es

			
			xor di, di
			call PrintFrame


			mov ah, WhiteOnMagenta
			mov si, offset RegisterName
			mov di, 164d				; = (80 + 2) * 2 next line and 2 symbol
			
			
			mov cx, 13					; number of registers
			@@loop:
				call PrintRegister		; fetches the register value from the stack 
										; and writes it into the frame
				inc bp
				inc bp

				add di, 146d			; the length of the text about registers is 7 characters
										; = (80 - 7) * 2 
			loop @@loop


			pop bp

			ret
			endp
;----------------------------------------------------

;----------------------------------------------------
; removes the frame and fills the video memory 
; with information from the array
;
; Destr: ax, bx, cx, dx, di, si
;----------------------------------------------------
RemoveFrame		proc

				push cs
				pop ds

				xor di, di
				xor dx, dx
				xor cx, cx

				mov si, offset AddressSavesVideoMem
				push 0b800h
				pop es
				

				@@loop_1:
					cmp cx, FrameHeight
					je @@exit_1
					inc cx
					
					
					@@loop_2:
						cmp dx, FrameLength
						je @@exit_2

						mov ax, word ptr ds:[si]
						mov word ptr es:[di], ax

						add si, 2
						add di, 2

						inc dx
						jmp @@loop_2

					@@exit_2:
					xor dx, dx
					add di, 138d 				; (80 - 11) * 2

					jmp @@loop_1
				@@exit_1:

				ret 
				endp
;----------------------------------------------------

;----------------------------------------------------
; saves information from video memory into an array
;
; Destr: ax, bx, cx, dx, di, si
;----------------------------------------------------
SaveVideoMem 	proc

				push cs
				pop ds

				xor di, di
				xor dx, dx
				xor cx, cx

				mov si, offset AddressSavesVideoMem
				push 0b800h
				pop es
				

				@@loop_1:
					cmp cx, FrameHeight
					je @@exit_1
					inc cx
					
					
					@@loop_2:
						cmp dx, FrameLength
						je @@exit_2

						mov ax, word ptr es:[di]
						mov word ptr ds:[si], ax

						add si, 2
						add di, 2

						inc dx
						jmp @@loop_2

					@@exit_2:
					xor dx, dx
					add di, 138d 				; (80 - 11) * 2

					jmp @@loop_1
				@@exit_1:

				ret 
				endp

				ret
            	endp
;----------------------------------------------------

;----------------------------------------------------
; the function supplements 
; the 8 (time) function 21 interrupts
;----------------------------------------------------
Int_08      proc
			
			push sp ss es ds bp di si dx cx bx ax
			
			mov al, cs:FrameFlag
			cmp al, 1d
			jne @@exit
			call PrintRegInfo
							
			@@exit:
			
			pop ax bx cx dx si di bp ds es ss sp

            	  db 	  0eah
old_int_08_ofs    dw      0
old_int_08_seg    dw      0

            iret
            endp
;----------------------------------------------------


;----------------------------------------------------
; the function supplements 
; the 9 (keybord) function 21 interrupts
;----------------------------------------------------
Int_09      proc

			push sp ss es ds bp di si dx cx bx ax

			
            in al, 60h						; keyboard ports
            cmp al, 0dh      				; '='
            jne @@exit
			mov al, cs:FrameFlag			; need update or not
			cmp al, 1d
			je @@remove_frame
				xor cs:FrameFlag, 1d
				call SaveVideoMem
				call PrintRegInfo
				jmp @@exit
			@@remove_frame:
				xor cs:FrameFlag, 1d
				call RemoveFrame	
			@@exit:

			

			pop ax bx cx dx si di bp ds es ss sp
			
            	  db 	  0eah
old_int_09_ofs    dw      0
old_int_09_seg    dw      0

            iret
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


            mov ax, 3509h				; bx = offset; es = segment of address function 09h
            int 21h						;
            mov old_int_09_ofs, bx
            mov bx, es
            mov old_int_09_seg, bx		; save old address of interupt function 09h
										; keybord

            mov bx, 4 * 09h  			; 4 * 09h = addres Int_09
			push 0
            pop es


            cli
            mov es:[bx], offset Int_09	; 0:[4 * 09h] = address of Int_09
            push cs
            pop ax
            mov es:[bx + 2], ax			; 0:[4 * 09h] = cs
            sti


			mov ax, 3508h				; bx = offset; es = segment of address function 08h
            int 21h						;
            mov old_int_08_ofs, bx
            mov bx, es
            mov old_int_08_seg, bx      ; save old address of interupt function 08h
                      					; time

            mov bx, 4 * 08h  			; 4 * 08h = addres Int_08
      		push 0
            pop es

    
            cli
            mov es:[bx], offset Int_08  ; 0:[4 * 08h] = address of Int_08
            push cs
            pop ax
            mov es:[bx + 2], ax			; 0:[4 * 08h] = cs
            sti


            mov ax, 3100h
            
            mov dx, offset EOP
            shr dx, 4
            inc dx

            int 21h
		
;----------------------------------------------------

EOP:

end		START
