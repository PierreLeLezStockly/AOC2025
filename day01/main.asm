section .data
    filename db "input.txt", 0

section .bss
    buffer resb 4096

section .text
    global main

main:
    mov rax, 1          ; syscall: write
    mov rdi, 1          ; file descriptor: stdout
    mov rsi, msg        ; pointer to message
    mov rdx, len        ; message length
    syscall
    mov rax, 60         ; syscall: exit
    xor rdi, rdi        ; exit code 0
    syscall
    leave
    ret
