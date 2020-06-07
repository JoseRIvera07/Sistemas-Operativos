;******************************** CONFIG CODE TO 16 BITS (RM) ***********************************

[bits 16]                                ; Set asembly to 16 bits, BIOS start on 16 bits secure mode
[org 0x7C00]  							 ; Origin address
global boot

;******************************** CONFIG OF BOOT & MEM SECTORS **********************************

boot:                                    ; Instruction to set up the bootloader

    jmp _start       
    TIMES 3-($-$$) DB 0x90               ; The fisrt 3 bits of the boot sector can't be code

    volumeLabel:       db    "TANK OS"  ; Volume label

;**************************************** STAGE 1 CODE ******************************************

_start:
                                         ; BIOS puts the address of the booting drive on the dl register
                                         ; Writing that addres into memory at [bootdrv]
    mov [BOOT_DRIVE], dl

                                         ; Setting the stack
    xor si, si
    mov ds, si
    mov bp, 0xA000                       ; Here we set our stack safely out of the
    mov sp, bp                           ; Way, at 0xA000
    mov bx, 0x7E00                       ; Load 5 sectors to 0x0000 (ES):0x7E00 (BX)
    mov dh, 6                            ; From the boot disk
    mov dl, [BOOT_DRIVE]
    jmp diskload

;**************************************** DISKLOAD CODE ******************************************
                                    
diskload:                                ; Load DH sectors to ES : BX from drive DL
    push dx                              ; Store DX on stack so later we can recall how many sectors were request to be read,
                                         ; even if it is altered in the meantime
    mov ah, 0x02                         ; BIOS read sector function
    mov al, dh                           ; Read DH sectors
    mov ch, 0x00                         ; Select cylinder 0
    mov dh, 0x00                         ; Select head 0
    mov cl, 0x02                         ; Start reading from second sector ( i.e. after the boot sector )
    int 0x13                             ; BIOS interrupt
    jc disk_error                        ; Jump if error ( i.e. carry flag set )
    pop dx                               ; Restore DX from the stack
    cmp dh , al                          ; If AL ( sectors read ) != DH ( sectors expected )
    jne disk_error                       ; Display error message
    
	mov si, msg                          ; Set the message to be printed
    call printString       				 ; Call the function to print the message
    call subs.sleep                      ; Call the wait function to show the message on screen for about 5 seconds

	jmp start

subs:                                    ; Sub-functions to wait & print char's

.sleep:						             ; Sentence to make the task wait 1 second
    mov     cx, 4Ah                      ; Upper 8-bits of the time to wait
    mov     dx, 9680h                    ; Lower 8-bits of the time to wait
    mov     ah, 86h                      ; BIOS interruption to be use
    int     15h                          ; Interruption to BIOS (TIME)

printCharacter:                          ; Function to print a char
    mov bh, 0x00                         ; Page to write
    mov bl, 0x07                         ; Color attribute
    mov ah, 0x0E                         ; Takes a single char in al
    int 0x10                             ; Interruption to BIOS (VIDEO)
    ret

printString:               				 ; Funtion to print an String untill the null terminated char
    
    .loop:  
		mov al, [si]
		inc si
		or al, al                        
        jz .end                          ; Jump to the end of the function
        call printCharacter              ; Print character in al
    	jmp .loop                            ; Print next character
    .end:                                 ; End point of the loop
    ret                                  

disk_error:                              ; Function to indicate an ERROR LOADING THE DISK
	mov dx , DISK_ERROR_MSG              ; Message to be printed
	call print                           ; Call another functionto print the message
	jmp $                                ; Jump to the last PC addres Save

print:                                   ; Takes pointer to the string to be displayed  in dx
	mov ah,0x0e                          ; Takes a single char in al
	wr:                                  
	    mov byte al,[edx]                ; Move a byte of the message to al
	    cmp al,0                         ; Compare if al is 0 -> the end of the string
	    jz return                        ; If equals jump to the return point
	    int 0x10                         ; Set video mode to print the char
	    inc dx                           ; Increment dx pointer
	    jmp wr                           ; Jump to the begin of the loop to print the next char
	return:                              ; Return point
	ret

                                         ; Variables

DISK_ERROR_MSG: db " Error al leer el Disco", 0
msg: db "Cargando juego... ", 0
msg1: db "Listo!", 0

;**************************************** END OF 1 STAGE - CODE ******************************************

BOOT_DRIVE: db 0                         ; Store the drive addres given by the BIOS

                                         ; The first sector MUST be 512 bytes and the last 2 bytes have to be 0xAA55 for it
                                         ; To be bootable
times 510 -($-$$) db 0
dw 0xAA55  ; magic number 

;**************************************** MAIN CODE **********************************************

section .text

mov sp, 0xA000
start:                                   ; Start the game 

	xor ah, ah
	xor al, al
	xor bh, bh
	xor bl, bl

	mov si, msg1                         ; Set the message to be printed
    call printString       				 ; Call the function to print the message
    call subs.sleep                      ; Call the wait function to show the message on screen for about 5 seconds
    

    call start_graphics_mode             ; Init the graphics mode
    call init_array                      ; Init the game array
	call put_food                        ; Init the function to set the food on the board

    MainLoop:                            ; MainLoop of the game control
		call display_score               ; Call the function to draw the score on screen
		call draw_background             ; Call the function to draw the background of the game on screen
		call draw_frame                  ; Call the function to draw the border of the game area
		call sleep                       ; Call a function to stop the proces for a few miliseconds
		mov ax, [gameState]              ; Update the status of the game
		cmp ax, 0                        ; Compare if game_status is equal 0
		jne MainLoop                     ; Jump to the begin of the loop to set the Game over msg
		call update                      ; Call the function to update the values of the game
		call handle_input                ; Call the function to react after an user input
		jmp MainLoop                     ; Jump to the begin of the loop to re-do all the game check again
    ret

    arr: dw 0x9005                       ; Main game array (49,49) that represents  the screen 
	head_x: db 23                        ; X coordinate of snake head 	
	head_y: db 24	                     ; Y coordinate of snake head 	 
	direction: db 2                      ; Direction that the snake is moving to 0= up ; 1 = down ; 2 = left ; 3 = right
	tail_x: db 25                        ; X coordinate of snake tail     
	tail_y: db 24                        ; Y coordinate of snake tail	  
	dir_arr: dw 0x9a00                   ; Pointer to [dir_array] start 
	snakeLength: dw 3                    ; The length of the snake 
	table: db "0123456789ABCDEF"         ; Translation table used for printing hex and decimal score
	score: dw 0                          ; The score of the player 	
	gameState: dw 0                      ; The state of the game 0= playing ; 1= gameOver 
	gameOverMsg:                         ; Game Over messages
		db 10,10,10,10,10,10,10,10,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,"Game Over!",10,13
		db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,"Your Score",10,13 
		db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h ,0
	pressRestart:                        ; Press Restart messages
		db 10,13,20h,20h,20h,20h,20h,20h,20h,20h, "Press any key to Restart" ,0

;**************************************** CORE OF THE GAME - CODE ******************************************

init_array:
	push bx 
	push cx 
	push ds 
    xor bx,bx

    loop12:
		mov si , [arr] ; array address
        mov  [si+bx], byte 0 
        inc bx
		mov ax , 2401
        cmp bx ,ax
        jl loop12
	
	mov si , [arr]
    mov bx , 1199
    mov byte [si+bx] ,   1
    mov bx , 1200
    mov byte [si+bx] ,   1
    mov bx , 1201
    mov byte [si+bx] ,   1
	
	mov si , [dir_arr]
    mov bx , 0
    mov byte [si+bx] ,   2
    mov bx , 1
    mov byte [si+bx] ,   2
	
	call put_obsatcles
	pop ds 
	pop cx 
	pop bx 
    ret

draw_frame:
    xor cx ,cx 	; x =1 
	;mov cx , 24

	loop44: 
		xor di ,di  ; y = 0
		;mov di , 24

		loop55:   
			push di  ; di = 0
			push cx
			mov ax , 49  ; ax = 49
			mul di       ; ax = 0
			add ax , cx  ; ax = 0 + 1 = 1
			mov bx , ax  ; bx = 1
			mov si , word [arr]  
			mov al , byte [si+bx]  ; al = 1  
			cmp al , 1  ;  ; true
			jne loop555  ;

		draw:
			push ax 
			mov ax , 4   ; ax = 4 
			mul di       ;  ax = 0
			mov bx , 2   ; bx = 2
			add ax , bx  ; ax = 2 
			
			mov si , ax  ; j = y*4+2  = dx = 2 
			mov ax , 4   ;  ax = 4
			mul cx       ;  ax = 2*1 = 2
			mov bx , 62  ;  bx = 62 
			add ax ,bx   ; i = x*4+62 ; ax = 64 

			pop bx 
			push ax 
			push si
			push 4
			push 4 
			push 0fh
			call draw_rectangle 
			add esp , 10 
			jmp endloop

			loop555:
				cmp al , 2 
				je draw 

			endloop:
				pop cx   ; cx =1 
				pop di   ; di = 0
				inc di   ; di = 1
				mov ax , 49 
				cmp di , ax  
				jl loop55

		inc cx 
		mov ax , 49 
		cmp cx ,ax 
		jl loop44

	ret
			
handle_input:
	mov ah , 01h ;check keyboard status
	int 16h 
	jz _none 
	
	mov ah , 10h  ; get pressed key
	int 16h
	
	;get the key in al 
	cmp al , 'w'
	je up 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp al ,  's'
	je down 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cmp al ,  'a' 
	je left 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
	cmp al ,  'd' 
	je right     
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ah = extend key scan code 
	cmp ah , 48h 
	je up 
	cmp ah , 50h 
	je down 
	cmp ah , 4bh 
	je left 
	cmp ah , 4dh 
	je right 
	jmp _none

	up: 
		mov byte bl , [direction]
		cmp bl , 1 
		je _ignore
		mov byte [direction] , 0 
		ret 

	down: 
		mov byte bl , [direction]
		cmp bl , 0
		je _ignore
		mov byte [direction] , 1 
		ret

	left: 
		mov byte bl , [direction]
		cmp bl , 3 
		je _ignore
		mov byte [direction] , 2 
		ret 

	right:
		mov byte bl , [direction]
		cmp bl , 2 
		je _ignore
		mov byte [direction] , 3 
		ret 

	_ignore:

	_none: 
		ret 

update:  
	mov al , byte [head_x]
	mov cl , byte [head_y]
	mov bl , byte [direction] 
	cmp bl , 0 
	je _movUp
	cmp bl , 1 
	je _movDown
	cmp bl , 2 
	je _movLeft
	cmp bl , 3 
	je _movRight 
	ret

	_movUp: 
		cmp cl , 0  ; y = 0 
		je _tunUp 
		dec cl  	; y=y-1
		jmp return_update

	_movDown: 
		cmp cl , 48 ; y
		je _tunDwn
		inc cl  ; y = y+1
		jmp return_update

	_movLeft: 
		cmp al , 0 
		je _tunLeft
		dec al ; x=x-1
		jmp return_update  

	_movRight:  
		cmp al , 48 
		je _tunRight 
		inc al ; x=x+1
		jmp return_update 
	
	_tunUp: 
		mov cl , 48 
		jmp return_update 

	_tunDwn: 
		mov cl , 0 
		jmp return_update 

	_tunLeft: 
		mov al , 48 
		jmp return_update 

	_tunRight:
		mov al , 0 
		jmp return_update 
		
	return_update:  
		mov byte [head_x] , al 
		mov byte [head_y] , cl 
		push ax 
		push cx  
		
		mov byte bl , [direction] 
		
		mov si , [dir_arr]
		mov ax , [snakeLength] 
		dec ax 
		add si , ax 
		mov byte [si] , bl 
		
		call check
		
		pop cx 
		pop ax
		
		push ax 
		push cx 
		push 1 
		call set_value
		add esp , 6	 
		ret

	end_update:
		ret	
		
set_value: 
	mov byte cl , [esp+6]
	mov byte al , [esp+4]
	xor dx , dx 
	mov dx , [esp+2]
	xor ah , ah 
	xor ch , ch 
	mov bl , 49 
	mul bl 
	add ax , cx
	mov bx , ax  
	mov di , word [arr] ;word [si]
	mov  byte [di+bx] , dl
	ret
	
sleep: 
	mov si , 1
	mov bx , [46ch] 
	xor di  ,di

	timer: 
		mov ax  , [46ch]
		sub ax , bx 
		cmp ax ,2 
		jl timer
		mov bx , [46ch]
		inc di 
		cmp di , si
		jl timer 
	ret
	

remove_tail: 
	xor cx , cx 
	xor bx , bx
	xor ax , ax
	mov cl , [tail_x]
	mov bl , [tail_y]
	
	push cx 
	push bx 
	push 0 
	call set_value
	add esp , 2 
	
	mov bx , [dir_arr]
	mov byte al , [bx]  
	
	pop bx 
	pop cx 
	
	cmp al , 0 
	je tail_up 
	cmp al , 1 
	je tail_down 
	cmp al , 2 
	je tail_left 
	cmp al , 3 
	je tail_right 
	jmp end_tail 

	tail_up: 
		cmp bl, 0 
		je tuntup 
		dec bl 
		jmp return_tail 
		
	tail_down: 
		cmp bl, 48 
		je tuntdown 
		inc bl 
		jmp return_tail 
	
	tail_left: 
		cmp cl, 0 
		je tuntleft 
		dec cl 
		jmp return_tail 
	
	tail_right: 
		cmp cl, 48 
		je tuntright 
		inc cl 
		jmp return_tail 
		
	tuntup: 
		mov bl , 48
		jmp return_tail
		
	tuntdown: 
		mov bl , 0
		jmp return_tail
	
	tuntleft: 
		mov cl , 48
		jmp return_tail
		
	tuntright: 
		mov cl , 0
		jmp return_tail 
		
	return_tail: 
		mov byte [tail_x] , cl 
		mov byte [tail_y] , bl 
		
		call shift_array 

	end_tail: 
		ret



print_decimal:   
	xor dx , dx 
	mov ax , [esp+2]  ; 1023
	mov bx , 10000 
	div bx  
	
	;mov al , ah
	mov bx , table 
	xlat
	mov ah , 0x0e 
	int 10h 
	
	mov ax , dx 
	xor dx , dx 
	mov bx , 1000 
	div bx 
	
	mov bx , table 
	xlat
	mov ah , 0x0e 
	int 10h 
	
	mov ax , dx
	xor dx , dx 
	mov bx  ,100 
	div bx 
	
	mov bx , table 
	xlat
	mov ah , 0x0e  
	int 10h 
	
	mov ax , dx 
	xor dx , dx 
	mov bx , 10 
	div bx 
	
	mov bx , table 
	xlat
	mov ah , 0x0e 
	int 10h  
	
	mov ax , dx 
	mov bx , table 
	xlat 
	mov ah , 0x0e 
	int 10h
	ret 
	
	
display_score: 
	mov al , 13 
	mov ah , 0x0e 
	int 10h 
	
	mov word ax , [score]
	push ax 
	call print_decimal 
	add esp , 2 
	
	ret
	
rng: 
	xor dx , dx
	mov ax ,[46ch] 
	mov bx , 49  
	div bx  
	xor dh , dh 
	xor ax , ax 
	mov ax , dx 
	ret 
	
rng2: 
	xor dx , dx 
	mul al 
	mov bx , 49  
	div bx  
	xor dh , dh 
	xor ax , ax 
	mov ax , dx 
	ret 
	
get_value: 
	mov byte cl , [esp+4]  ;x 
	mov byte al , [esp+2]  ;y
	xor ah , ah 
	xor ch , ch
	mov bl , 49 
	mul bl 
	add ax , cx
	mov bx , ax  
	xor ax ,ax 
	mov di , word [arr] 
	mov  al , byte [di+bx] 
	ret
	
put_food: 
	xor cx , cx 
	xor bx , bx

	checkSnakeBody: 
		call rng  
		push ax	
		call rng2 
		mov cx , ax 
		pop bx 
		push bx 
		push cx 
		call get_value 
		pop cx 
		pop bx
		xor ah , ah
		cmp al , 1  
		je checkSnakeBody 
		cmp al , 2 
		je checkSnakeBody
	push bx
	push cx 
	push 2 
	call set_value  
	add esp , 6
	ret  

check:  
	push ax 
	push bx 
	push cx 
	push dx 
	push di 
	push si 

	xor bx , bx 
	xor ax , ax 
	xor cx , cx
	
	mov cl , [esp+16]  ; x  
	mov bl , [esp+14]  ; y
	
	push cx 
	push bx 
	call get_value 
	pop bx 
	pop cx
	
	xor ah , ah  
	;cmp al , 1 
	;je _dead 
	cmp al , 2 
	je _eat 
	jmp _mov 
	
	_dead: 
		mov word [gameState] , 1 
		call sleep
		call sleep
		call sleep 
		call sleep 
		call sleep 
		call Game_over
		jmp end_check

	_eat: 
		mov si , word [score] 
		inc si 
		mov word [score] , si 
		
		mov si ,word  [snakeLength] 
		inc si 
		mov word [snakeLength] , si 
		call put_food
		jmp end_check 

	_mov:
		call remove_tail 

	end_check:
		pop si 
		pop di 
		pop dx 
		pop cx 
		pop bx
		pop ax 
		ret 
	
shift_array:  
		xor si , si   
		mov si , 1
		shiftLoop: 
			mov bx , [dir_arr] 
			mov byte cl , [bx+si] 
			mov byte [bx+si-1] , cl 
			mov di , word [snakeLength]
			inc si 
			cmp si , di
			jl shiftLoop 
		ret  
		
put_obsatcles: 
	mov bx, [arr] 
	;----------------------Encierro de Águila--------------
	;Borde Superior
	mov byte [bx+200], 1 
	mov byte [bx+201], 1 
	mov byte [bx+202], 1 
	mov byte [bx+203], 1 
	mov byte [bx+204], 1 
	mov byte [bx+205], 1 
	;Borde Derecho
	mov byte [bx+205], 1
	mov byte [bx+254], 1
	mov byte [bx+303], 1
	mov byte [bx+352], 1
	mov byte [bx+401], 1
	mov byte [bx+450], 1
	;Borde Izquierdo
	mov byte [bx+200], 1 
	mov byte [bx+249], 1 
	mov byte [bx+298], 1 
	mov byte [bx+203], 1 
	mov byte [bx+347], 1 
	mov byte [bx+396], 1 

	;Borde Inferiro
	mov byte [bx+396], 1 
	mov byte [bx+397], 1 
	mov byte [bx+398], 1 
	mov byte [bx+399], 1 
	mov byte [bx+400], 1 
	mov byte [bx+401], 1 
	;----------------------------- Laberinto -------------------------------------------
	mov byte [bx+1000], 1 
	mov byte [bx+1001], 1 
	mov byte [bx+1002], 1 
	mov byte [bx+1003], 1 
	mov byte [bx+1004], 1 
	mov byte [bx+1005], 1 
	mov byte [bx+1000], 1 
	mov byte [bx+1007], 1 
	mov byte [bx+1000], 1 
	mov byte [bx+1009], 1 
	mov byte [bx+1010], 1 
	mov byte [bx+1011], 1 


	ret
	
	
Game_over:  
	push 0 
	push 0 
	push 320                  ; clear screen 
	push 200 
	push 0 
	call draw_rectangle 
	add esp , 10 
	
	xor bx , bx 

	displaymsg: 
		mov byte al , [gameOverMsg+bx]  
		cmp al , 0
		jz return_it
		mov ah , 0x0e 
		int 10h  
		 inc bx 
		jmp displaymsg 

	return_it:
		mov word ax ,[score] 
		push ax 
		call print_decimal 
		add esp , 2  
		xor bx , bx

		displaymsg2: 
			mov byte al , [pressRestart+bx]  
			cmp al , 0
			jz return_it2
			mov ah , 0x0e 
			int 10h  
			 inc bx 
			jmp displaymsg2 
			  
	return_it2:
		mov ah , 10h 
		int 16h   
		
		db 0x0ea 
		dw 0xffff ; jmp far 0xffff (CTRL+ALT+DEL) 
		dw 0x0000 
		ret

;**************************************** GRAPHICS - CODE ******************************************

start_graphics_mode:
    mov ah,0x0
    mov al,13h
    int 10h
    ret

draw_pixel:
	; ds , es , fs , gs , cs , si , di , bx 
    mov cx, 0A000h ; The offset to video memory
    mov es,cx
    mov ax,[esp+4] ; Y coord
    mov cx,320     
    mul cx
    mov bx,[esp+6] ; X coord
    add ax,bx
    mov di,ax
    mov dx,[esp+2]
    mov byte [es:di],dl
    ret

draw_rectangle:
	push ax 
	push bx 
	push cx 
	push dx 
	push si 
	push di 
	push ds 
    xor bx,bx

    loop1:
        xor ax,ax

        loop2:
            mov di , [esp+24] ;x
            mov si , [esp+22] ;y

            add di ,bx
            add si ,ax

            mov dx , [esp+16] ; color
            push dx
            push bx
            push ax
            push di
            push si
            push dx
            call  draw_pixel
            add esp,6
            pop ax
            pop bx
            pop dx

            mov si , [esp+18] ; height
            inc ax
            cmp ax , si
            jl loop2

        mov di , [esp+20] ; width
        inc bx
        cmp bx , di
        jl loop1

	pop ds 
	pop di 
	pop si 
	pop dx 
	pop cx 
	pop bx 
	pop ax 
    ret

draw_background:
    push 60
    push 0
    push 2
    push 200
    push 0fh    ; left border
    call draw_rectangle
    add esp , 10

    push 60
    push 0
    push 200
    push 2
    push 0fh   ;  top border
    call draw_rectangle
    add esp , 10

    push 258
    push 0
    push 2      ; right border 
    push 200
    push 0fh
    call draw_rectangle
    add esp , 10

    push 60
    push 198
    push 200
    push 2         ; 
    push 0fh
    call draw_rectangle
    add esp , 10

    push 62
    push 2
    push 196
    push 196
    push 6fh
    call draw_rectangle
    add esp , 10
    ret



;------------------------------------------------------
;cx = xpos , dx = ypos, si = x-length, di = y-length, al = color
drawBox:
	push si               ;save x-length
	.for_x:
		push di           ;save y-length
		.for_y:
			pusha
			mov bh, 0     ;page number (0 is default)
			add cx, si    ;cx = x-coordinate
			add dx, di    ;dx = y-coordinate
			mov ah, 0xC   ;write pixel at coordinate
			int 0x10      ;draw pixel!
			popa
		sub di, 1         ;decrease di by one and set flags
		jnz .for_y        ;repeat for y-length times
		pop di            ;restore di to y-length
	sub si, 1             ;decrease si by one and set flags
	jnz .for_x            ;repeat for x-length times
	pop si                ;restore si to x-length  -> starting state restored
	ret
    
stop_graphics_mode:
    mov ax , 03h 
    int 10
	ret 

times (0x400000 - 512) db 0

db 	0x63, 0x6F, 0x6E, 0x65, 0x63, 0x74, 0x69, 0x78, 0x00, 0x00, 0x00, 0x02
db	0x00, 0x01, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
db	0x20, 0x72, 0x5D, 0x33, 0x76, 0x62, 0x6F, 0x78, 0x00, 0x05, 0x00, 0x00
db	0x57, 0x69, 0x32, 0x6B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x00, 0x00, 0x00, 0x78, 0x04, 0x11
db	0x00, 0x00, 0x00, 0x02, 0xFF, 0xFF, 0xE6, 0xB9, 0x49, 0x44, 0x4E, 0x1C
db	0x50, 0xDA, 0xBD, 0x45, 0x83, 0xC5, 0xCE, 0xC1, 0xB7, 0x2A, 0xE0, 0xF2
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00






    

    

