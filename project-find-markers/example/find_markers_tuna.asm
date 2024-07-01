#------------------------------------------------------------------------------------------------
# Description : This program is aimed to detect markers according to the specification
# described in following document's section 3.22. The detection marker is the type 11. (Page 61)
# https://galera.ii.pw.edu.pl/~zsz/ecoar/ecoar_projects_2022_2023_fall.pdf
# Author: Ahmet Tunahan Cinsoy
# Date : 2024.05.06 (yyyy-mm-dd)
#------------------------------------------------------------------------------------------------

# Input .bmp image specifications are:
# Sub Format: 24 bit RGB - no compression
# Size: width: 320 px, height: 240px
# File Name: 'source.bmp'

# Expected Output:
# Console window  plain text - subsequent lines contain the coordinates of the detected 
# markers, eg. 10, 15. The point (0,0) is in the upper left corner of the image. 

# Remarks:
# 1. Check the input data and signal errors (e.g. wrong file format) 
# 2. We assume that the drawing may contain 50 markers (at most) of a given type. 

# Input image will have 320x240 (width x height) pixels, so in total -> 76,800 pixels
# Each pixel in the image will have 24 bits, which is equal to 3 bytes. (8 bits for R, 8 bits for G, 8 bits for B)
# So the total size of the input image becomes 76,800 x 3 = 230,400 bytes
.eqv BMP_FILE_SIZE 230400

# Each row in the image will have 320 x 3 = 960 bytes
.eqv BYTES_PER_ROW 960

	.data
# Input image will have 230,400 bytes, so we need to allocate a space for it
res:	.space	2 # When deleted, program gives an error saying: Load address not aligned to word boundary 0x1001000a
image:	.space	BMP_FILE_SIZE
# width and height static variables will be used in iterations to check end of the image
width:	.word	320
height: .word	240

fname:	#.asciz "source.bmp"
	#.asciz "source2.bmp"
	.asciz "test.bmp"
	.text
main:
	# Starting with reading input bmp image
	call	read_bmp
	
	# Initializing input parameters a0 and a1
	call initialize_input_parameters
	call iterate
	
	# After operations are done, call exit function
	call exit
	
# ============================================================================

iterate:
	call restore_loop_parameters
	
	# Initialize i (outer loop counter)
	li s0, 0	# s0 will be i and is initialized to 0

outer_loop:
	# Check if i (s0) == height (t1)
	beq s0, t1, end_outer_loop
	
	# Initialize j (inner loop counter)
	li s1, 0	# s1 will be j and is initialized to 0

inner_loop:
	# Check if j (s1) == width (t3)
	beq s1, t3, end_inner_loop

	mv a0, s1 # Moving inner-loop iterator s1 into a0, because get_pixel expects to receive a0 (x coordinate) as input parameter
	mv a1, s0 # Moving ouuter-loop iterator s0 into a1, because get_pixel expects to receive a1 (y coordinate) as input parameter
	
	call get_pixel
	
	call restore_loop_parameters
	
	## In here, a0 register holds the hex value of the current pixel
	call check_black_pixel
	
	call restore_loop_parameters
	
	# a0 and a1 might be modified during the function calls, so it's better to reinitialize them with current iterators' values
	mv a0, s1 
	mv a1, s0
	
	# Increment j (inner loop counter)
	addi s1, s1, 1
	
	# Jump back into inner loop to go on in horizontal direction
	j inner_loop

end_inner_loop:
	# Jump back to the outer loop condition
	addi s0, s0, 1
	j outer_loop
	

end_outer_loop:
	ret
	
# ============================================================================

initialize_input_parameters:
	#get pixel color - $a0=x, $a1=y, result $v0=0x00RRGGBB
	li	a0, 0
	li	a1, 0
	ret
	
# ============================================================================

restore_loop_parameters:
	xor t0 ,t0, t0
	xor t1, t1, t1
	xor t2, t2, t2
	xor t3, t3, t3
	la t0, height	# Load address of the height variable
	lw t1, 0(t0)	# Load value of height into t1
	addi t1, t1, -1 # The top-leftmost index is 0, so in total we need to iterate until we reach height-1
	la t2, width	# Load address of the width variable
	lw t3, 0(t2)	# Load value of width into t3
	addi t3, t3, -1 # The top-leftmost index is 0, so in total we need to iterate until we reach width-1
	ret
	
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	addi sp, sp, -4		#push $s1
	sw s1, 0(sp)
#open file
	li a7, 1024
        la a0, fname		#file name 
        li a1, 0		#flags: 0-read file
        ecall
	mv s1, a0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#read file
	li a7, 63
	mv a0, s1
	la a1, image
	li a2, BMP_FILE_SIZE
	ecall

#close file
	li a7, 57
	mv a0, s1
        ecall
	
	lw s1, 0(sp)		#restore (pop) s1
	addi sp, sp, 4
	ret

# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	a0 - x coordinate
#	a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	a0 - 0RGB - pixel color

	la t1, image		#adress of file offset to pixel array
	addi t1,t1,10
	lw t2, (t1)		#file offset to pixel array in $t2
	la t1, image		#adress of bitmap
	add t2, t1, t2		#adress of pixel array in $t2
	
	#pixel address calculation
	li t4,BYTES_PER_ROW
	mul t1, a1, t4 		#t1= y*BYTES_PER_ROW
	mv t3, a0		
	slli a0, a0, 1
	add t3, t3, a0		#$t3= 3*x
	add t1, t1, t3		#$t1 = 3x + y*BYTES_PER_ROW
	add t2, t2, t1	#pixel address 
	
	#get color
	lbu a0,(t2)		#load B
	lbu t1,1(t2)		#load G
	slli t1,t1,8
	or a0, a0, t1
	lbu t1,2(t2)		#load R
        slli t1,t1,16
	or a0, a0, t1
					
	ret

check_black_pixel:
	beqz a0, black_pixel_detected
	ret

black_pixel_detected:
	# s0 holds the y value of the coordinate of the current black pixel
	# s1 hold the x value of the coordinate of the current black pixel
	
	# What we basically need is:
	# First of all, store the x and y values (if it's the desired marker, we will display these coordinates)
	# Start from s0 and travel vertically up until rgb value becomes white or height - 1 value is reached, hold the count of each pixel traversed
	# Once it is white or height-1 value is reached, store the count of each pixel traversed
	# Go back to the first coordinate, and start traversing horizontally to right, up until white pixel occurs or width - 1 value is reached, hold the count of each pixel traversed
	# After these iterations, divide traversedVerticalPixels / traversedHorizontalPixels and check if it is 1/2
	# If it is, then display stored x and y coordinates, if it is not, continue the loopIteration
	
	
	j exit
# ============================================================================

exit:	li 	a7,10		#Terminate the program
	ecall