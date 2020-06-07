org 0x7C00
%define SECTOR_AMOUNT 0x10  ;Precompiler defined value for easy changing
jmp short start
nop

                                ; BPB
OEMLabel		db "Example "	; Disk label
BytesPerSector		dw 512		; Bytes per sector
SectorsPerCluster	db 1		; Sectors per cluster
ReservedForBoot		dw 1		; Reserved sectors for boot record
NumberOfFats		db 2		; Number of copies of the FAT
RootDirEntries		dw 224		; Number of entries in root dir
LogicalSectors		dw 2880		; Number of logical sectors
MediumByte		db 0F0h		    ; Medium descriptor byte
SectorsPerFat		dw 9		; Sectors per FAT
SectorsPerTrack		dw 18		; Sectors per track (36/cylinder)
Sides			dw 2		    ; Number of sides/heads
HiddenSectors		dd 0		; Number of hidden sectors
LargeSectors		dd 0		; Number of LBA sectors
DriveNo			dw 0		    ; Drive No: 0
Signature		db 41		    ; Drive signature: 41 for floppy
VolumeID		dd 00000000h	; Volume ID: any number
VolumeLabel		db "Example    "; Volume Label: any 11 chars
FileSystem		db "FAT12   "	; File system type: don't change!
start: 
; ------------------------------------------------------------------

;Initialize Registers
cli
xor ax, ax
mov ds, ax
mov ss, ax
mov es, ax
mov fs, ax
mov gs, ax
mov sp, 0x6ef0 ; setup the stack like qemu does
sti

                      ;Reset disk system
mov ah, 0
int 0x13              ; 0x13 ah=0 dl = drive number
jc errorpart
                      ;Read from harddrive and write to RAM
mov bx, 0x8000        ; bx = address to write the kernel to
mov al, SECTOR_AMOUNT ; al = amount of sectors to read
mov ch, 0             ; cylinder/track = 0
mov dh, 0             ; head           = 0
mov cl, 2             ; sector         = 2
mov ah, 2             ; ah = 2: read from drive
int 0x13   		      ; => ah = status, al = amount read
jc errorpart

mov si, msg                          ; Set the message to be printed
call printString       				 ; Call the function to print the message
call subs.sleep  

mov si, msg1                         ; Set the message to be printed
call printString       				 ; Call the function to print the message
call subs.sleep  

jmp 0x8000

errorpart:            ;if stuff went wrong you end here so let's display a message
mov si, errormsg
mov bh, 0x00          ;page 0
mov bl, 0x07          ;text attribute
mov ah, 0x0E          ;tells BIOS to print char
.part:
lodsb
sub al, 0
jz end
int 0x10              ;interrupt
jmp .part
end:
jmp $

errormsg db "Failed to load...",0

msg: db "Loading Tanks Game... ", 0
msg1: db "Game is Ready, Enjoy!", 0


printCharacter:                          ; Function to print a char
    mov bh, 0x00                         ; Page to write
    mov bl, 0x07                         ; Color attribute
    mov ah, 0x0E                          ; Takes a single char in al
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


subs:                                    ; Sub-functions to wait & print char's

.sleep:						             ; Sentence to make the task wait 1 second
    mov     cx, 4Ah                      ; Upper 8-bits of the time to wait
    mov     dx, 9680h                    ; Lower 8-bits of the time to wait
    mov     ah, 86h                      ; BIOS interruption to be use
    int     15h                          ; Interruption to BIOS (TIME)


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
times 510-($-$$) db 0
        ;Begin MBR Signature
db 0x55 ;byte 511 = 0x55
db 0xAA ;byte 512 = 0xAA

