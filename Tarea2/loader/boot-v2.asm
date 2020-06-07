;******************************** CONFIG CODE TO 16 BITS (RM) ***********************************

[bits 16]                                ;set asembly to 16 bits, BIOS start on 16 bits secure mode

;******************************** CONFIG OF BOOT & MEM SECTORS **********************************

boot:                                    ;Instruction to set up the bootloader

    jmp start       
    TIMES 3-($-$$) DB 0x90               ;The fisrt 3 bits of the boot sector can't be code

    volumeLabel:       db    "SNAKE OS" ;Volume label

;**************************************** STAGE 1 CODE ******************************************

start:

    ;BIOS puts the address of the booting drive on the dl register
    ;Writing that addres into memory at [bootdrv]
    mov [bootdrv], dl

    ;Setting the stack
    mov ax, 07C0h
    add ax, 288
    mov ss, ax              ;ss = stack space
    mov sp, 4096            ;sp = stack pointer

    mov ax, 07C0h
    mov ds, ax              ;ds = data segment

    mov ah, 00h             ;Set video mode to graphical
    mov al, 13h             ;13h - graphical mode, 40x25. 256 colors.;320x200 pixels. 1 page.

    int 10h                 ;Call

	;The function print text

	;Loading Tetris From Disk ...

    mov ax, 0x0e4c
	int 10h                 ;Call
	mov ax,  0x0e6f
	int 10h                 ;Call
	mov ax,  0x0e61 
	int 10h                 ;Call
	mov ax, 0x0e64 
	int 10h                 ;Call
	mov ax, 0x0e69 
	int 10h                 ;Call
	mov ax, 0x0e6e 
	int 10h                 ;Call
	mov ax, 0x0e67 
	int 10h                 ;Call
	mov ax, 0x0e20
	int 10h                 ;Call
	mov ax, 0x0e54
	int 10h                 ;Call
	mov ax, 0x0e65 
	int 10h                 ;Call
	mov ax, 0x0e74 
	int 10h                 ;Call
	mov ax, 0x0e72 
	int 10h                 ;Call
	mov ax, 0x0e69
	int 10h                 ;Call
	mov ax, 0x0e73
	int 10h                 ;Call
	mov ax, 0x0e20
	int 10h                 ;Call
	mov ax, 0x0e46
	int 10h                 ;Call
	mov ax, 0x0e72
	int 10h                 ;Call
	mov ax, 0x0e6f
	int 10h                 ;Call
	mov ax, 0x0e6d
	int 10h                 ;Call
	mov ax, 0x0e20
	int 10h                 ;Call
	mov ax, 0x0e44
	int 10h                 ;Call
	mov ax, 0x0e69
	int 10h                 ;Call
	mov ax, 0x0e73 
	int 10h                 ;Call
	mov ax, 0x0e6b 
	int 10h                 ;Call
	mov ax, 0x0e20 
	int 10h                 ;Call
	mov ax, 0x0e2e 
	int 10h                 ;Call
	mov ax, 0x0e2e 
	int 10h                 ;Call
	mov ax, 0x0e2e
	int 10h                 ;Call

    ;draw_Tetris basic game space
    call subs.sleep
    push 1                  ;column
    push 1                  ;row
    push 28                 ;msg length
    push msg2               ;msg to write
    call print_text

    ;Only have 512 bytes of space on the first stage,
    ;So on the first stage write the text 
    ;and then jump to second stage
    ;Restore the direction of the booting drive
    mov dl, [bootdrv]

jump_to_stage2:

    mov ah, 0x02
    mov al, 1               ;Number of sectors to read
    mov ch, 0               ;Cylinder number
    mov dh, 0               ;Head number
    mov cl, 2               ;Starting sector number. 2 because 1 was already loaded.
    mov bx, stage2          ;Where the stage 2 code is, points to stage 2 code

    int 0x13

    mov dl, 0x80
    jc jump_to_stage2       ;If error loading, set dl to 0x80 and try again

    jmp stage2              ;Jump to stage 2 code 

; Stage 1 functions

subs:

.sleep:						;sentence to ake the task wait 1 second
    mov     CX, 4AH
    mov     DX, 9680H
    mov     AH, 86H
    int     15H

print_text:                 ;Instruction to print messages on screen

    push bp                 ;Save old base pointer
    mov bp, sp              ;Use the current stack pointer as new base pointer
    pusha

    mov ax, 7c0h            ;Beginning of the code
    mov es, ax
    mov cx, [bp + 6]        ;Length of string
    mov dh, [bp + 8]        ;Row to put string
    mov dl, [bp + 10]       ;Column to put string
    mov bp, [bp + 4]       

    mov ah, 13h             ;Function 13 - write string
    mov al, 01h             ;Attrib in bl, move cursor
    mov bh, 1
    mov bl, 0Fh             ;Color white

    int 10h
                            ;Restore the stack and return
    popa                    ;Pop the data a
    mov sp, bp              ;Set the stack pointer to the previous base pointer
    pop bp                  ;Pop the bp data

    ret 8                   ;Return code 8 of execution

; Store the drive addres given by the BIOS
bootdrv: db 0              

; Data
msg1:    db "Loading Tetris From Disk ..."
msg2:    db "                            "
height: db 50
width: db 10

    ;The first sector MUST be 512 bytes and the last 2 bytes have to be 0xAA55 for it
    ;To be bootable

times 510 - ($ - $$) db 0   ; Padding with 0 at the end
dw 0xAA55                   ; PC boot signature


;**************************************** STAGE 2 CODE ******************************************

section .text

stage2:

%DEFINE EMPTY 0b0000_0000
%DEFINE SNAKE 0b0000_0001
%DEFINE FRUIT 0b0000_0010
%DEFINE EATEN 0b0000_0100
%DEFINE WRECK 0b0000_1000
%DEFINE DIRUP 0b0001_0000
%DEFINE DIRDO 0b0010_0000
%DEFINE DIRLE 0b0100_0000
%DEFINE DIRRI 0b1000_0000
%define map(i) byte [es:i]
%define head word [es:1024]
%define tail word [es:1026]
%define fpos word [es:1028]
%define ftim word [es:1030]
%define rand word [es:1032]


init:
	.segments:
		mov ax, 0x07C0
		mov ds, ax
		mov ax, 0x7E00
		mov es, ax
		mov ax, 0xA000
		mov gs, ax
		mov ax, 0
		mov fs, ax
	.random:
		mov ah, 0
		int 0x1A
		mov rand, dx
	.display:
		mov ah, 0x00
		mov al, 0x13
		int 0x10
	.interrupt:
		mov [fs:0x08*4], word timer
		mov [fs:0x08*4+2], ds
		mov [fs:0x09*4], word keyboard
		mov [fs:0x09*4+2], ds


main:
	hlt
	jmp main


;; () -> (ax); ax,cx,dx
random:
	mov ax, rand
	mov dx, 7993
	mov cx, 9781
	mul dx
	add ax, cx
	mov rand, ax
	ret

;; (si) -> (di,ah:al) ; cx,dx
movement: 
	mov cl, map(si)
	mov ax, si
	mov dl, 32
	div dl
	test cl, DIRUP
	jz $+4
	dec al
	test cl, DIRDO
	jz $+4
	inc al
	test cl, DIRLE
	jz $+4
	dec ah
	test cl, DIRRI
	jz $+4
	inc ah
	and al, 31
	and ah, 31
	movzx di, al
	rol di, 5
	movzx cx, ah
	add di,cx
	ret


keyboard:
	in al, 0x60
	mov bx, head
	mov ah, map(bx)
	cmp al, 0x39
	jne $+12
	mov cx, 1032
	mov al, 0
	mov di, 0
	rep stosb
	and ah, 0x0F
	cmp al, 0x48
	jne $+5
	or ah, DIRUP
	cmp al, 0x50
	jne $+5
	or ah, DIRDO
	cmp al, 0x4b
	jne $+5
	or ah, DIRLE
	cmp al, 0x4d
	jne $+5
	or ah, DIRRI
	test ah, 0xF0
	jz $+4
	mov map(bx), ah
	mov al, 0x61
	out 0x20, al
	iret

timer:
	.tick_rtc:
		int 0x70
	.move_head:
		mov si, head
		call movement
		mov ah, map(di)
		mov al, map(si)
		test al, WRECK
		jz $+3
		iret
		test ah, SNAKE|EATEN
		jz $+7
		mov map(si), WRECK
		iret
		test ah, FRUIT
		jz $+20
		mov ftim, 0
		mov fpos, -1
		mov bl, EATEN
		jmp $+4
		mov bl, SNAKE
		and al, 0xF0
		or bl, al
		mov map(di), bl
		mov head, di
	.move_tail:
		mov si, tail
		call movement
		mov al, map(si)
		test al, SNAKE
		jz $+11
		mov map(si), EMPTY
		mov tail, di
		jnz $+9
		and al, 0xF0
		or al, SNAKE
		mov map(si), al
	.move_fruit:
		cmp ftim, 0
		jne $+42
		mov bx, fpos
		mov map(bx), EMPTY
		call random
		mov bx, ax
		and bx, 1023
		cmp map(bx), EMPTY
		jne $-13
		mov map(bx), FRUIT
		mov fpos, bx
		mov ftim, 0
		dec ftim
	.redraw:
		mov cx, 0
		mov ax, cx
		mov dl, 32
		div dl
		mov bx, ax
		movzx ax, bl
		;add ax, 9			; pos y
		mov dx, 320
		mul dx
		movzx dx, bh
		add ax, dx
		;add ax, 24			;pos x
		mov dx, 5
		mul dx
		mov di, cx
		mov dl, map(di)
		and dl, 0x0F
		cmp dl, EMPTY
		jne $+8
		mov ebx, 0x02020202
		cmp dl, SNAKE
		jne $+8
		mov ebx, 0x01010101
		cmp dl, FRUIT
		jne $+8
		mov ebx, 0x04040404
		cmp dl, EATEN
		jne $+8
		mov ebx, 0x05050505
		mov di, ax
		mov [gs:di],ebx
		add di, 320
		mov [gs:di],ebx
		add di, 320
		mov [gs:di],ebx
		add di, 320
		mov [gs:di],ebx
		inc cx
		cmp cx, 1024
		jne .redraw+3
	iret