section .data
	filename db "input.txt", 0
	filename_len equ $-filename

	err_msg db "Error\n", 0
	err_msg_len equ $-err_msg

; Assumes it will fit the entire input
; This makes things MUUUUUCH easier
section .bss
	buffer resb 4096

section .text
	global main

main:
	push rbp
	mov rbp, rsp
	sub rsp, 16 ; [rbp - 8] for FD, [rbp - 16] for bytes read

	; Open input file
	mov rax, 2 ; sys_open
	mov rdi, filename
	mov rsi, 0 ; O_RDONLY
	syscall

	; Check for error then store FD
	cmp rax, 0
	jl .error
	mov [rbp - 8], rax

	; Read in buffer
	mov rax, 0
	mov rdi, [rbp - 8]
	mov rsi, buffer
	mov rdx, 4095
	syscall

	; Check for error then NULL-terminate the buffer
	cmp rax, 0
	jl .error
	mov word [buffer + rax + 1], 0
	mov [rbp - 16], rax

	; Print buffer
	mov rax, 1
	mov rdi, 1
	mov rsi, buffer
	mov rdx, [rbp - 16]
	syscall

	; Exit cleanly
	mov rax, 60
	mov rdi, 0
	syscall


.error:
	mov rax, 1 ; sys_write
	mov rdi, 2
	mov rsi, err_msg
	mov rdx, err_msg_len
	syscall
	
	mov rax, 60 ; sys_exit
	mov rdi, 1
	syscall
