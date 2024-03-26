# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to replace all digits in a string with it's complement
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

    # Save biggest address
    mv t0, a0
    li t1, 0    # Current number
    li t2, 0    # Flag
    li t3, '0'
    li t4, '9'

# Loop over all characters and change
loop:
    lbu a0, (t0)
    beqz a0, end

    blt a0, t3, next_char
    bgt a0, t4, next_char

    bnez t2, increment_count

    li t2, 1

    j next_char

# Go to next char
next_char:
    addi t0, t0, 1
    j loop

# Save the result
increment_count:
    addi t1, t1, 1
    j next_char

end:
    # Display the output message
    li a7, 4
    la a0, output
    ecall

    # Display the result
    li a7, 1
    mv a0, t1
    ecall

    # Exit
    li a7, 10
    ecall
