section .data
	filename db "input.txt", 0
	filename_len equ $-filename

	err_msg db "Error", 10, 0
	err_msg_len equ $-err_msg

; Assumes it will fit the entire input
; This makes things MUUUUUCH easier
section .bss
	buffer resb 32001
	output resb 21 ; 20 digits for 64-bit number + 1 for newline

section .text
	global main

main:
	push rbp
	mov rbp, rsp
	sub rsp, 32 ; [rbp - 8] for dial value, [rbp - 16] for total, [rbp - 24] for FD, [rbp - 32] for bytes read

.load_input:
	; Open input file
	mov rax, 2 ; sys_open
	mov rdi, filename
	mov rsi, 0 ; O_RDONLY
	syscall

	; Check for error then store FD
	cmp rax, 0
	jl .error
	mov [rbp - 24], rax

	; Read in buffer
	mov rax, 0
	mov rdi, [rbp - 24]
	mov rsi, buffer
	mov rdx, 32000
	syscall

	; Check for error then NULL-terminate the buffer
	cmp rax, 0
	jl .error
	mov byte [buffer + rax], 0
	mov [rbp - 32], rax

	mov rcx, 0
	mov qword [rbp - 16], 0
	mov qword [rbp - 8], 50 ; Dial value


; RCX is the buffer index
; RDX gets the letter ('L' or 'R')
; RSI gets the digit
; RDI gets the number (0 to 99)
.loop:
	; Get next byte and check for buffer end
	movzx rdx, byte [buffer + rcx]
	cmp rdx, 0
	je .end

	mov rdi, 0
	add rcx, 1

.get_number:
	; Add the first digit
	movzx rsi, byte [buffer + rcx]
	cmp rsi, 10 ; \n
	je .dial
	cmp rsi, 0
	je .dial

	imul rdi, 10
	sub rsi, '0'
	add rdi, rsi
	add rcx, 1
	jmp .get_number

.dial:
	; Check which way to turn the dial
	cmp rdx, 'R'
	je .pos

.neg:
	sub [rbp - 8], rdi
	jmp .modulo

.pos:
	add [rbp - 8], rdi

.modulo:
	; Computes signed modulo of dial
	mov rax, [rbp - 8]
	mov r8, 100
	cqo
	idiv r8
	mov [rbp - 8], rdx

	; Make result positive if negative
	cmp rdx, 0
	jge .skip_adjust
	add qword [rbp - 8], 100

.skip_adjust:
	; Check if Dial points on 0
	mov rax, [rbp - 8]
	test rax, rax
	jnz .next
	add qword [rbp - 16], 1

.next:
	add rcx, 1
	jmp .loop

.end:
	mov rdi, [rbp - 16]
	call .print_number

	push 0
	jmp .exit

; Assumes its a u64
; Input in RDI
.print_number:
	mov rsi, output + 20
	mov byte [rsi], 0
	dec rsi
	mov byte [rsi], 10

	mov rax, rdi
	mov rcx, 10

.convert_loop:
	; Computes RAX / RCX
	; RAX gets the quotient, RDX gets the remainder
	mov rdx, 0
	div rcx

	; Convert digit to ascii and write it into the buffer
	add dl, '0'
	dec rsi
	mov [rsi], dl

	; Check if quotient is 0
	test rax, rax
	jnz .convert_loop

.print:
	; Computes length
	mov rdx, output + 20
	sub rdx, rsi

	mov rax, 1
	mov rdi, 1
	syscall
	ret

.error:
	mov rax, 1 ; sys_write
	mov rdi, 2
	mov rsi, err_msg
	mov rdx, err_msg_len
	syscall
	
	push 1
	jmp .exit

; Assumes exit code is on top of the stack
.exit:
	pop rdi
	mov rax, 60 ;sys_exit
	syscall
