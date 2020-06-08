org 0x8000
bits 16

;precompiler constant
%define entityArraySize 16
;Let's begin by going into graphic mode

iniciar:
	mov word [gameState], 0

	mov word [coinFound], 0

	call initGraphics

	;Now let's register some custom interrupt handlers
	call registerInterruptHandlers

	;init map
	call initMap

	

;Main game loop
gameLoop:
	call resetBuffer ;reset screen to draw on empty canvas
	
	;MODULAR DRAWING CODE
	mov di, entityArray
	add di, 2 ;skip drawing player
	.nextEntity:
	cmp [di], word 0
	je .skip
		pusha
		mov cx, [player+2] ;player x to draw relative
		mov dx, [player+4] ;player z to draw relative
		mov di, [di]
		call drawEntity
		popa
	.skip:
	add di, 2
	cmp di, entityArray+((entityArraySize-1)*2) ;confirm that di is still pointing into the entityArray
	jl .nextEntity
	
	call drawMap
	
	; PLAYER DRAWING CODE
	mov si, [player]   ;get animation
	mov ax, [player+6] ;get index within animation
	xor dx,dx
	div word [si+2]    ; animation time % time of full animation
	mov ax, dx
	xor dx, dx
	div word [si]      ; (animation time % time of full animation) /  time of one frame
	add ax, ax         ; index*2 because image address is a word
	
	add si, 4          ;skip first two words of structure
	add si, ax		   ;add the offset to the frame
	mov si, [si]       ;set the image parameter to the image referenced in the frame
	
	mov ax, 80/2 - 9/2 - 1      ;center player image
	mov bx, 50/2 - 12/2 - 1     ;center player image
	call drawImage
	; END OF PLAYER DRAWING CODE
	
	call copyBufferOver ;draw frame to screen
	
	call gameControls ;handle control logic

	call checkEntitys

	call restartGame

	call synchronize ;synchronize emulator and real application through delaying
	


jmp gameLoop


jmp $

;di = entity cx,dx = xpos,zpos
drawEntity:
	push dx
	inc word [di+6]
	mov ax, [di+6] ;get index within animation
	mov si, [di]
	xor dx,dx
	div word [si+2]    ; animation time % time of full animation
	mov ax, dx
	xor dx, dx
	div word [si]      ; (animation time % time of full animation) /  time of one frame
	add ax, ax         ; index*2 because image address is a word
	
	add si, 4          ;skip first two words of structure
	add si, ax		   ;add the offset to the frame
	mov si, [si]       ;set the image parameter to the image referenced in the frame
	pop dx
	
	;mov si, word [di]   ;get animation
	;mov si, word [si+4] ;get first frame of animation
	
	mov ax, word [di+2] ;get entity x
	sub ax, cx          ;subtract the position of the player from the x position
	add ax, 80/2 - 9/2 - 1  ;relative to screen image drawing code for x position
	mov bx, word [di+4] ;get entity y
	sub bx, dx          ;subtract the position of the player from the z position
	add bx, 50/2 - 12/2 - 1 ;relative to screen image drawing code for z position
	call drawImage      ;draw image to buffer
	ret

;di = entity, cx = new_xpos, dx = new_zpos, bp = new animation
;fixed for modular entity system
checkEntitys:
	pusha                       ;save current state
	;mov si, coinFound         ;set si to entityArray
	mov bx, word [coinFound]          ;read entityArray entry
	cmp bx, 5               
	je .END
	jmp .Continue

	.END:
		;inc word [level]
		mov bx,word[level]
		cmp bx, 3
		je .END2
		jmp .Continue2

		.END2:
			call Game_over

		.Continue2:
			inc word [level]
			call iniciar
			jmp gameLoop
			popa
		;mov word [gameState], 1
		;call Game_over

	.Continue:
		popa                ;reload old register state
		ret

%define tileWidth      12
%define ASCIImapWidth  32
%define ASCIImapHeight 32
;bp = function to call, ah = search for, si = parameter for bp function
iterateMap: ;cambiar aqui el mapa
	push bx
	mov bx, word [level]
	cmp bx, 1
	je .MAP1 
	cmp bx, 2
	je .MAP2 
	cmp bx, 3
	je .MAP3 
	.MAP1:
		mov di, ASCIImap_1
		jmp .NEXT
		
	.MAP2:
		mov di, ASCIImap_2
		jmp .NEXT

	.MAP3:
		mov di, ASCIImap_3
		jmp .NEXT

	.NEXT:
		pop bx
		mov cx, 0x0 ; map start x
		mov dx, 0x0 ; map start y
		.next:
		mov al, [di]
		test al, al
		je .stop    ; stop when null terminator found
		cmp al, ah
		jne .skip   ; skip if the character is not the one this iteration is searching for
		push ax     ; save the content of ax
		call bp     ; call the specified function of this iteration
		pop ax
		jc .term    ; the carry flag determines if the specified function has found what it was searching for (and thus exits)
		.skip:
			inc di                           ; point to the next character
			add cx, tileWidth                ; increase x pixel position
			cmp cx, ASCIImapWidth*tileWidth  ; check if x position is at the end of the line
			jl .next
		sub dx, tileWidth                    ; decrease y pixel position
		xor cx, cx                           ; reset x position
		jmp .next
		.stop:
			clc
		.term:
		ret

checkForCollision:
	pusha                       ;save current state
	mov si, entityArray         ;set si to entityArray
	.whileLoop:
	mov bx, word [si]   ;read entityArray entry
	test bx, bx         ;if entry is zero => end of array
	jz .whileSkip
	cmp bx, di          ;if entity is equal to di => next entity to not collide with it self
	jz .whileSkip
	
	mov ax, word [bx+2] ;ax = entity x
	sub ax, 8           ;subtract 8 because of hitbox
	cmp ax, cx ; (entityX-8 <= playerX)
		jg .whileSkip
		
	mov ax, word [bx+2] ;ax = entity x
	add ax, 8           ;add 8 because of hitbox
	cmp ax, cx ; (entityX+8 > playerX)
		jle .whileSkip

	mov ax, word [bx+4] ;ax = entity z
	sub ax, 10          ;subtract 10 because of hitbox
	cmp ax, dx ; (entityZ-10 <= playerZ)
		jg .whileSkip
		
	mov ax, word [bx+4] ;ax = entity z
	add ax, 9           ;subtract 9 because of hitbox
	cmp ax, dx ; (entityZ+9 > playerZ)
		jle .whileSkip
		
	;if we reach this point => actual collision
	;mov cx, [di+2]         ;set new x pos to current x pos => no movement
	;mov dx, [di+4]         ;set new z pos to current z pos => no movement
	
	mov word [si], 0
	inc word [coinFound]
	
	;ding ding count found
	
	jmp .noMapCollision
	.whileSkip:
	add si, 2           ;set si to the next entry in the entityArray
	cmp si, entityArray+((entityArraySize-1)*2)
	jl .whileLoop
	.whileEnd
;------------------------------------------------
	pusha
	mov si, cx
	mov bx, dx
	call collideBlockProtection
	popa
	jnc .noMapCollisionP
		;if we reach this point => actual collision
		mov cx, [di+2]         ;set new x pos to current x pos => no movement
		mov dx, [di+4]         ;set new z pos to current z pos => no movement
	.noMapCollisionP:
;---------------------------------------------------------
		pusha
		mov si, cx
		mov bx, dx
		call collideMap
		popa
		jnc .noMapCollision
		;if we reach this point => actual collision
		mov cx, [di+2]         ;set new x pos to current x pos => no movement
		mov dx, [di+4]         ;set new z pos to current z pos => no movement
		;call Game_over
		.noMapCollision:
		mov byte [canWalk], 1
		mov word [di]   ,bp  ;update the animation in use
		mov word [di+2] ,cx  ;update x pos
		mov word [di+4] ,dx  ;update y pos
	popa                 ;reload old register state
	ret

canWalk db 0

gameControls:
	
	mov byte [canWalk], 0
	mov di, player ;select the player as the main entity for "checkForCollision"
	mov al, byte [pressA]
	add al, byte [pressD]
	cmp al, 0
	jz .nokeyad
		mov cx, word [player_PosX] ;set cx to player x
		mov dx, word [player_PosZ] ;set dx to player z
		mov bp, [player]           ;set bp to current animation
		cmp byte [pressD], 1 ;try to move x+1 if 'd' is pressed and set animation accordingly, test other cases otherwise
		jne .nd
		inc cx
		mov bp, tankImg_right
		.nd:
		cmp byte [pressA], 1 ;try to move x-1 if 'a' is pressed and set animation accordingly, test other cases otherwise
		jne .na
		dec cx
		mov bp, tankImg_left
		.na:
		call checkForCollision ;check if player would collide on new position, if not change position to new position
	.nokeyad:
	mov al, byte [pressW]
	add al, byte [pressS]
	cmp al, 0
	jz .nokeyws
		mov cx, word [player_PosX] ;set cx to player x
		mov dx, word [player_PosZ] ;set dx to player z
		mov bp, [player]           ;set bp to current animation
		cmp byte [pressW], 1 ;try to move z-1 if 'w' is pressed and set animation accordingly, test other cases otherwise
		jne .nw
		dec dx
		mov bp, tankImg_back
		.nw:
		cmp byte [pressS], 1 ;try to move z+1 if 's' is pressed and set animation accordingly, test other cases otherwise
		jne .ns
		inc dx
		mov bp, tankImg_front
		.ns:
		call checkForCollision ;check if player would collide on new position, if not change position to new position
	.nokeyws:
	cmp byte [canWalk], 0
	jnz .noCollision
		mov word [player+6], 0 ;reset animation counter
		ret
	.noCollision:
		inc word [player+6]  ;update animation if moving
		ret
	
;======================================== NEW STUFF ==========================================
registerInterruptHandlers:
	mov [0x0024], dword keyboardINTListener ;implements keyboardListener
	ret
	
;; NEW KEYBOARD EVENT BASED CODE
pressA db 0
pressD db 0
pressW db 0
pressS db 0
pressR db 0
keyboardINTListener: ;interrupt handler for keyboard events
	pusha	
		xor bx,bx ; bx = 0: signify key down event
		inc bx
		in al,0x60 ;get input to AX, 0x60 = ps/2 first port for keyboard
		btr ax, 7 ;al now contains the key code without key pressed flag, also carry flag set if key up event
		jnc .keyDown
			dec bx ; bx = 1: key up event
		.keyDown:
		cmp al,4bh ;izq
		jne .check1         
			mov byte [cs:pressA], bl ;use cs overwrite because we don't know where the data segment might point to
		.check1:
		cmp al,4dh ;derecha
		jne .check2
			mov byte [cs:pressD], bl
		.check2:
		cmp al,48h ;arriba
		jne .check3
			mov byte [cs:pressW], bl
		.check3:
		cmp al,50h ;abajo
		jne .check4
			mov byte [cs:pressS], bl
		.check4:
		cmp al,0x1e ;a
		jne .check5
			mov byte [cs:pressR], bl
		.check5:
		mov al, 20h ;20h
		out 20h, al ;acknowledge the interrupt so further interrupts can be handled again 
	popa ;resume state to not modify something by accident
	iret ;return from an interrupt routine
	
;using interrupts instread of the BIOS is SUUPER fast which is why we need to delay execution for at least a few ms per gametick to not be too fast
synchronize:
	pusha
		mov si, 20 ; si = time in ms
		mov dx, si
		mov cx, si
		shr cx, 6
		shl dx, 10
		mov ah, 86h
		int 15h ;cx,dx sleep time in microseconds - cx = high word, dx = low word
	popa
	ret

;cx, dx = xpos, zpos, si = animation
;eax == 0 => success, else failed
addEntity:
	pusha
	mov bx, cx
	mov di, entityArray
	xor ax, ax
	mov cx, (entityArraySize-1)
	repne scasw                 ; iterate through entity array until empty stop is found
	sub di, 2
	test ecx, ecx               ; abort here if at the end of the the entity array
	je .failed
	sub cx, (entityArraySize-1) ; calculate index within the array by using the amount of iterated entires
	neg cx
    shl cx, 3
	add cx, entityArrayMem
	mov [di], cx
	mov di, cx
	mov [di], si
	mov [di+2], bx ; set x position of the entity
	mov [di+4], dx ; set y position of the entity
	xor bx, dx     ; "randomise" initial animation position
	mov [di+6], bx ; set animation state
	popa
	xor eax, eax   ; return 0 if successfully added
	ret
	.failed:
		popa
		xor eax, eax
		inc eax       ; return 1 if failed to find a place for the entity
		ret

;di = entity cx,dx = xpos,zpos
drawBlock:
	mov ax, word [player+2]
	sub ax, cx
	imul ax, ax
	mov bx, word [player+4]
	sub bx, dx
	imul bx, bx
	add ax, bx
	cmp ax, 3000 ;calculate distance
	jge .skip

	mov ax, cx
	mov bx, dx
	sub ax, word [player+2]   ;subtract the position of the player from the x position
	add ax, 80/2 - 9/2 - 1    ;relative to screen image drawing code for x position
	sub bx, word [player+4]   ;subtract the position of the player from the z position
	add bx, 50/2 - 12/2 - 1   ;relative to screen image drawing code for z position
	call drawImage            ;draw image to buffer
	.skip:
	clc
	ret
	
;set the position of the player to x=cx, z=dx
setSpawn:
	mov word [player+2], cx ; set player x
	mov word [player+4], dx ; set player z
	add word [player+4], 3  ; offset player z
	clc
	ret
	
;spawn the coins add set the spawn position of the player
initMap:
	mov si, tank2Img_right
	mov bp, addEntity
	mov ah, 'R'
	call iterateMap
	mov si, tank2Img_front
	mov bp, addEntity
	mov ah, 'D'
	call iterateMap
	mov si, tank2Img_left
	mov bp, addEntity
	mov ah, 'L'
	call iterateMap

	call spawnPlayer ; set spawn for player
	ret
	
;draw the map
drawMap:
	mov si, boxImg_0
	mov bp, drawBlock
	mov ah, '0'
	call iterateMap ; iterate the map and add a box at every '0' on the map
	;this second iteration is pretty unefficient but only optional for some ground texture
	mov si, tileImg_0
	mov bp, drawBlock
	mov ah, ' '
	call iterateMap ; iterate the map and add a tile at every ' ' on the map

	mov si, boxImg_1
	mov bp, drawBlock
	mov ah, '1'
	call iterateMap ; iterate the map and add a tile at every '1' on the map

	mov si, agila
	mov bp, drawBlock
	mov ah, 'X'
	call iterateMap ; iterate the map and add a tile at every 'X' on the map

	mov si, arbusto
	mov bp, drawBlock
	mov ah, '2'
	call iterateMap ; iterate the map and add a tile at every ' ' on the map


	ret
	
; si = player X, bx = player Y
collideMap:
	mov bp, blockCollison
	mov ah, '0'
	call iterateMap ; iterate the map and check for a collision with a '0'
	ret


collideBlockProtection:
	mov bp, blockCollison
	mov ah, '1'
	call iterateMap ; iterate the map and check for a collision with a '0'
	ret

;set the spawn of the player to the field 'P'
spawnPlayer:
	mov bp, setSpawn
	mov ah, 'P'
	call iterateMap ; iterate the map and set the player position to the last 'P' found on the map
	ret
	
;si = player x, bx = player z, cx = block x, dx = block z
blockCollison:
	push cx
	push dx
	sub cx, 8    ;subtract 8 because of hitbox
	cmp cx, si ; (blockX-8 <= playerX)
		jg .skip
	add cx, 8+8          ;add 8 because of hitbox
	cmp cx, si ; (blockX+8 > playerX)
		jle .skip
	sub dx, 10          ;subtract 10 because of hitbox
	cmp dx, bx ; (blockZ-10 <= playerZ)
		jg .skip
	add dx, 9+10         ;subtract 9 because of hitbox
	cmp dx, bx ; (blockZ+9 > playerZ)
		jle .skip
		stc
		jmp .end
	.skip:
		clc
	.end:
	pop dx
	pop cx
	ret
	
%include "buffer.asm"

restartGame:
	pusha
	;mov bx, word [gameState]
	;cmp bx, 1
	;je .RESTART
	;jmp .noGameOver
	;.RESTART:
	mov al, byte [pressR]
	cmp al, 0
	jz .noGameOver
	jmp .REINICIAR
	.REINICIAR
		mov word [level], 1
		;inc word [level]
		call iniciar
		jmp gameLoop
		popa 
			
	.noGameOver:
		popa
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
		mov word ax ,[level] 
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


;game value

gameState: dw 0                      ; The state of the game 0= playing ; 1= gameOver 
gameOverMsg:                         ; Game Over messages
	db 10,10,10,10,10,10,10,10,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,"Level Over!",10,13
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,"Your Level",10,13 
	db 20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h,20h ,0
pressRestart:                        ; Press Restart messages
	db 10,13,20h,20h,20h,20h,20h,20h,20h,20h, "Press R key to Restart" ,0

coinFound dw 0

level dw 1

table: db "0123456789ABCDEF"         ; Translation table used for printing hex and decimal score

;entity array

entityArray:
			dw player
			resw entityArraySize

;player structure
player:
player_Anim  dw tankImg_right ;pointer to animation
player_PosX  dw 0x32              ;position of player (x)
player_PosZ  dw 0x32               ;position of player (z)
player_AnimC dw 0               ;animation counter

;entity structure
box:
box_Anim  dw boxImg          ;pointer to animation
box_PosX  dw 0x10            ;position of box (x)
box_PosZ  dw 0x10            ;position of box (z)
box_AnimC dw 0               ;animation counter

;other entity structures:
entityArrayMem:
	resw entityArraySize*4

;animation structure
tankImg_front:
	dw 5
	dw 10
	dw tank_Down_1
	dw tank_Down_2
	dw 0
	
tankImg_back:
    dw 5
	dw 10
	dw tank_Up_1
	dw tank_Up_2
	dw 0
	
tankImg_right:
    dw 5
	dw 10
	dw tank_Right_1
	dw tank_Right_2
	dw 0
	
tankImg_left:
	dw 5
	dw 10
	dw tank_Left_1
	dw tank_Left_2
	dw 0
	
boxImg:
	dw 1            ;time per frames
	dw 1            ;time of animation
	dw boxImg_0     ;frames
	dw 0            ;zero end frame
;------------------------------------------------------------
tank2Img_front:
	dw 5
	dw 10
	dw tank2_Down_1
	dw tank2_Down_2
	dw 0
	
	
tank2Img_right:
    dw 5
	dw 10
	dw tank2_Right_1
	dw tank2_Right_2
	dw 0
	
tank2Img_left:
	dw 5
	dw 10
	dw tank2_Left_1
	dw tank2_Left_2
	dw 0


tank2_Down_1 incbin "img/bin/tank2_Down_1.bin"
tank2_Down_2 incbin "img/bin/tank2_Down_2.bin"
tank2_Right_1 incbin "img/bin/tank2_Right_1.bin"
tank2_Right_2 incbin "img/bin/tank2_Right_2.bin"
tank2_Left_1 incbin "img/bin/tank2_Left_1.bin"
tank2_Left_2 incbin "img/bin/tank2_Left_2.bin"
;-------------------------------------------------------

ASCIImap_1    incbin "img/bin/map1.bin"

agila  incbin "img/bin/agila.bin"
boxImg_0     incbin "img/bin/block1.bin"
boxImg_1     incbin "img/bin/bloque2.bin"
arbusto      incbin "img/bin/arbusto.bin"
tileImg_0    incbin "img/bin/tile.bin"
ASCIImap_2    incbin "img/bin/map2.bin"
;------------------------------------------------------------
tank_Up_1 incbin "img/bin/tank_Up_1.bin"
tank_Up_2 incbin "img/bin/tank_Up_2.bin"
tank_Down_1 incbin "img/bin/tank_Down_1.bin"
tank_Down_2 incbin "img/bin/tank_Down_2.bin"
tank_Right_1 incbin "img/bin/tank_Right_1.bin"
tank_Right_2 incbin "img/bin/tank_Right_2.bin"
tank_Left_1 incbin "img/bin/tank_Left_1.bin"
tank_Left_2 incbin "img/bin/tank_Left_2.bin"
;-------------------------------------------------------
ASCIImap_3    incbin "img/bin/map3.bin"


%assign usedMemory ($-$$)
%assign usableMemory (512*64)
%warning [usedMemory/usableMemory] Bytes used
times (512*64)-($-$$) db 0 ;kernel must have size multiple of 512 so let's pad it to the correct size
;times (512*1000)-($-$$) db 0 ;toggle this to use in bochs