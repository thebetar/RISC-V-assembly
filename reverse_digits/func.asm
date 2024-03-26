# ---------------------------------
# author        : Lars Vonk (@thebetar)
# date          : 2024-03-25
# description   : This script is used to reverse the digits in a string.
# ---------------------------------

    .data
input:  .space	80
prompt: .asciz	"Enter a string with number sequences: "
output: .asciz	"The complement of the string is: "

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
    li t1, -1       # Initialize result

    li t2, '0'      # Smallest digit
    li t3, '9'      # Largest digit

# Loop over all characters and find digits
loop:
    lbu a1, (t0)
    beqz a1, end

    # Check if character is a digit
    blt a1, t2, check_digit_seq
    bgt a1, t3, check_digit_seq

    bgez t1, continue
    mv t1, t0

    j continue

check_digit_seq:
    bltz t1, continue
    addi t5, t0, -1
    j reverse

continue:
    addi t0, t0, 1
    j loop

reverse:
    lb a4, (t1)
    lb a5, (t5)
    sb a4, (t5)
    sb a5, (t1)
    addi t1, t1, 1
    addi t5, t5, -1
    blt t1, t5, reverse

    li t1, -1
    j continue

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
