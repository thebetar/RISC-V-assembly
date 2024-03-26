# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to find the biggest number in a string.
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
    li t2, 0    # Biggest number
    li t3, '0'
    li t4, '9'

# Loop over all characters and change
loop:
    lbu a0, (t0)
    beqz a0, end
    blt a0, t3, check_result
    bgt a0, t4, check_result

    # Convert char to int
    sub a0, a0, t3
    li a4, 10
    mul t1, t1, a4
    add t1, t1, a0

    j next_char

# Check if the current number is bigger than the biggest number
check_result:
    bgt t1, t2, save_result
    li t1, 0

# Go to next char
next_char:
    addi t0, t0, 1
    j loop

# Save the result
save_result:
    mv t2, t1
    li t1, 0

    j next_char

end:
    # Display the output message
    li a7, 4
    la a0, output
    ecall

    # Display the result
    li a7, 1
    mv a0, t2
    ecall

    # Exit
    li a7, 10
    ecall
