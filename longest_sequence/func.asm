# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to replace all digits in a string with it's complement
# ---------------------------------

        .data
input:  .space	80
prompt: .asciz	"\nEnter a string with number sequences: "
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

        # Setup variables
        la t0, input    # Load address of input
        li t1, 0        # Current digit
        li t2, 0        # Largest digit

        li t3, '0'      # Smallest digit
        li t4, '9'      # Largest digit

# Loop over all characters and find largest
loop:
    lbu a1, (t0)
    beqz a1, end

    # Check if character is a digit
    blt a1, t3, reset_current
    bgt a1, t4, reset_current

    # Convert char to int
    sub a1, a1, t3
    li a2, 10
    mul t1, t1, a2
    add t1, t1, a1

    j next_char

reset_current:
    bgt t1, t2, set_max # Calculate complement
    li t1, 0            # Reset current digit if not max

next_char:
    addi t0, t0, 1
    j loop

set_max:
    mv t2, t1           # Set current digit as max
    li t1, 0            # Reset current digit
    j next_char         # Jump back to next character

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
