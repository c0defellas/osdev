	;;--------------------------------------
	;;    Custom bootloader
	;;--------------------------------------
	[BITS 16]
	[ORG  0x7c00]

	jmp start; skip data

	BOOTDRV   db 0
	DRVNO     db 0
	NERRORS   db 0
	BANNER    db "Custom bootloader", 0
	LOADMSG   db "Loading OS...", 0
	ERRMSG    db "Something went wrong...", 13, 10, 0
	ETRYAGAIN db "Error reading disk... try again.", 13, 10, 0

	OS_MAGIC db 1, 3, 3, 7
	OS_SKIPHDR equ 0004h

	;;       common routines
	%include "common.asm"

start:
	mov [BOOTDRV], dl; save the drive we booted from

	xor ax, ax
	mov ds, ax

	;;  Setup the stack after bootsector
	;;  0x7e0 << 4 == 0x7e00
	;;  0x7e00 - 0x7c00 == 0x200 == 512 bytes
	cli ; cli required, because BIOS could update sp
	mov ax, 0x7e0
	mov ss, ax
	mov sp, 0xffff; whole segment, 64Kib of stack

	xor  dx, dx; pos 0, 0
	call setcursor

	mov  si, BANNER
	call printstr

	mov  dl, 0
	mov  dh, 1; newline
	call setcursor

	mov  si, LOADMSG
	call printstr

	jmp loadOS

errLoading:
	mov  si, ETRYAGAIN
	call printstr

	mov  bl, NERRORS
	add  bl, 1
	test bl, 3
	jz   reboot

	mov [NERRORS], bl

loadOS:
	;   reset the disk controller
	xor ax, ax
	int 0x13
	jc  reboot

	;;  Load OS at 0x5000
	mov word ax, OS_SEGMENT
	mov es, ax
	xor bx, bx

	;;  ah = 02  -> BIOS service to read disk sectors
	;;  al = ??? -> number of sectors to read
	mov ah, 2

	;;  LOADNSECTORS must be passed as a macro (-D option) to nasm
	;;  It stores the number of sectors occuped by the operating system
	;;  It's computed in the make.sh
	mov al, LOADNSECTORS

	;;  set start CHS
	mov ch, 0; cylinder = 0
	mov cl, 2; sector = 2
	mov dh, 0; head = 0
	mov dl, [BOOTDRV]; disk = what we booted from
	int 0x13
	jc  errLoading

	;;  Check if we have a valid super block
	;;  ES already points to OS_SEGMENT
	mov di, 0; offset of OS magic signature
	mov si, OS_MAGIC
	cmpsw
	;;  If the operating system code does not start with OS_MAGIC
	;;  then aborts
	jnz error

	;;  It's very useful to set A20 line in the bootloader
	cli
	xor cx, cx

clear_buf:
	in     al, 64h; get input from keyboard status port
	test   al, 02h; test the buffer full flag
	loopnz clear_buf; loop until buffer is empty
	mov    al, 0D1h; keyboard: write to output port
	out    64h, al; output command to keyboard

clear_buf2:
	in     al, 64h; wait 'till buffer is empty again
	test   al, 02h
	loopnz clear_buf2
	mov    al, 0dfh; keyboard: set A20
	out    60h, al; send it to the keyboard controller

	;;  this is approx. a 25uS delay to wait for the keyboard controler
	;;  to execute our command
	mov cx, 14h

wait_kbc:
	out  0edh, ax
	loop wait_kbc

end:
	jmp OS_SEGMENT:OS_SKIPHDR

error:
	mov  si, ERRMSG
	call printstr

	jmp reboot
