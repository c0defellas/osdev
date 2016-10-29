	;;; Common configuration and routines

	OS_SEGMENT equ 0500h

	REBOOTMSG db "Press any key to reboot.", 0

	;;; Common routines

setcursor:
	pusha
	xor ax, ax
	mov ah, 2
	int 10h
	popa
	ret

clearscreen:
	pusha
	mov ax, 0x0600; clear the "window"
	mov cx, 0x0000; from (0, 0)
	mov dx, 0x184f; to (24, 79)
	mov bh, 0x07; keep light grey display
	int 0x10
	popa
	ret

printstr:
	;;  null-terminated string in SI
	pusha
	mov ah, 0Eh

.loop:
	lodsb
	cmp al, 0; end of string?
	je  .done

	int 10h
	jmp .loop

.done:
	popa
	ret

getkey:
	mov ah, 0; wait for key
	int 16h
	ret

reboot:
	mov  si, REBOOTMSG
	call printstr
	call getkey

	;; harcode jump to FFFF:0000 (reboot)
	db 0EAh
	dw 0000h
	dw 0FFFFh
	;; bye bye
