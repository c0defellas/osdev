	;; Entrypoint of operating system
	;; This is the first code executed, the bootloader catapulted us here
	;; at physical address specified in OS_SEGMENT:0004 in real mode and
	;; A20 address line set.

	[BITS 16]
	[ORG  0]

	MAGIC db 1, 3, 3, 7

	mov ax, OS_SEGMENT
	mov ds, ax; Set ds to easy access data

	jmp start

	BANNER db "Simple skeleton for an OS", 13, 10, 0

	%include "common.asm"

start:
	call clearscreen

	mov  si, BANNER
	call printstr

	call reboot
