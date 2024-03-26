.global _start



_start:
    # STDOUT FD = 1
    addi a7, zero, 64   # sys_write
    addi a0, zero, 1    # standard out file descriptor
    la a1, helloworld   # address of the string
    addi a2, zero, 13   # length of the string
    ecall               # call system

    addi a7, zero, 93   # exit systemcall
    addi a0, zero, 13   # exit code
    ecall               # call system

helloworld:
    .ascii "Hello, World!\n"