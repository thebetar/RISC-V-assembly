# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to replace all digits in a string with it's complement
# ---------------------------------

    .data
input:  .space	80
prompt: .asciz	"\nEnter a string: "
output: .asciz	"\nThe complement of the string is: "
buffer: .space  80

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

    # Move argument to temporary register
    mv t0, a0
    la t1, buffer
    li t2, '0'
    li t3, '9'

# Loop over all characters and change
loop:
    lbu t4, (t0)
    beqz t4, end

    blt t4, t2, save_char
    bgt t4, t3, save_char

    j next_char

# Save char
save_char:
    # Add character to t3 current string
    sb t4, (t1)
    addi t1, t1, 1
    # Move to next char

# Go to next char
next_char:
    addi t0, t0, 1
    j loop

end:
    # Display the output message
    li a7, 4
    la a0, output
    ecall

    # Display the result
    li a7, 4
    la a0, buffer
    ecall

    # Exit
    li a7, 10
    ecall
