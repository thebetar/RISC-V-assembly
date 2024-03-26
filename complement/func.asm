# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to read a string and change all digits to their complement.
# ---------------------------------

        .data
input:  .space	80
prompt: .asciz	"\nEnter a string: "
output: .asciz	"\nThe complement of the string is: "

        .text
main:
        # Display prompt
        li a7, 4
        la a0, prompt
        ecall

        # Read input
        li a7, 8
        la a0, input
        li a1, 80
        ecall

        # Modify the string
        mv t2, a0
        li t0, '0'
        li t1, '9'

# Loop over all characters and change
loop:
        lbu t3, (t2)
        beqz t3, end
        blt t3, t0, check_digit
        bgt t3, t1, check_digit
        sub t3, t1, t3
        add t3, t3, t0
        sb t3, (t2)
        addi t2, t2, 1
        j loop

# Check if value is a digit
check_digit:
        addi t2, t2, 1
        j loop

end:
        # Display the output message
        li a7, 4
        la a0, output
        ecall

        # Display the result
        li a7, 4
        la a0, input
        ecall

        # Exit
        li a7, 10
        ecall
