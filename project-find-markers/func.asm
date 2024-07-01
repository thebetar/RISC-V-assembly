# Set constant values to be used later
.eqv	IMG_HEADER		54
.eqv	IMG_BUFFER		230454		# bitmap pixel buffer size (320x240x3) + 54 bytes for header
.eqv	IMG_STRIDE		960		# bitmap stride (in bytes)

# Align 2 since the offset data is from byte 10 so overlap.
.data
.align 4
# Offset buffer by 2 bytes since the header is 4 aligned starting from the 3rd byte
offsetbuffer:			.space 2
buffer:				.space	IMG_BUFFER
# Offset buffer by 2 bytes since the header is 4 aligned starting from the 3rd byte
.align 4
offsetheader:			.space 2
header:				.space	IMG_HEADER
# Define data sections to store height and width
width:				.word	320
height:				.word	240
.align 0
filename:			.asciz	"/home/larsvonk/Classes/ECOAR/Project1/input.bmp"
opening_text:			.asciz	": Shape found on point: ("
separator_text:			.asciz	" | "
closing_text:			.asciz	")\n"
linebreak:			.asciz	"\n"
error_not_found_message:	.asciz	"File not found"
error_filetype_message:		.asciz	"Incorrect filetype"
error_size_message:		.asciz	"Incorrect filesize"
max_markers_message:		.asciz	"Max of 50 markers found"

.text
	# Set found counter
	li	s4, 1

	# Read file
	call	read_bmp

	# Jump to find markers
	j	start_check_pixel

# Read BMP file into the buffer	
read_bmp:
	# System call to open a file (stores file pointer in a0)
	# This creates a pointer to the file in the filesystem
	li	a7, 1024
	la	a0, filename
	li	a1, 0
	ecall
	
	# If filepointer is -1 than file not found and exit
	blt	a0, zero, error_not_found

	# Save file descriptor
	mv	t0, a0
		
	# Load file contents into buffer
	# From filesystem into memory
	li	a7, 63
	mv 	a0, t0
	la	a1, buffer
	li	a2, IMG_BUFFER
	ecall
	
	# Get filetype
	lbu	t1, 0(a1)
	lbu	t2, 1(a1)
	li	t3, 66
	li	t4, 77
	bne	t1, t3, error_filetype
	bne	t2, t4, error_filetype
	
	# Load width and height from file
	lw	t1, 18(a1)
	lw	t2, 22(a1)
	
	# Set values to check against in registers
	la	t3, width
	lw	t3, (t3)
	la	t4, height
	lw	t4, (t4)
	
	# Print for debugging purposes
	bne	t1, t3, error_size
	bne	t2, t4, error_size
	

	# System call to close a file
	li	a7, 57
	mv	a0, t0
	ecall

	ret

# Function to find markers in the image
start_check_pixel:
	# Restore parameters
	call 	restore_parameters

	# Initial input parameters
	li	a0, 0
	li	a1, 0

	# Iterate over all pixels in the image and print rgb
	li	t5, 0	# row
	li	t6, 0	# column

# Get pixels 
check_pixel:
	# Set parameters for get_pixel
	mv	a0, t6
	mv	a1, t5
	
	# Load the pixel value of current pixel (sets result in a0)
	call 	get_pixel
	
	# Restore parameters
	call 	restore_parameters
	
	# Check if current pixel stored in a0 is black
	call	check_black_pixel
	
	# If black pixel, check if pixel is at the corner of the shape
	call	check_bottom_right


# Checks if value in a0 is black
check_black_pixel:
	bnez	a0, end_check_pixel
	ret

# Checks the shape	
check_bottom_right:
	# X and Y are held in t6 (X) and t5 (Y)
	
	# Check if pixel is at the correct corner of a shape (see CheckBottomRight in C program)
	bge	t6, t3, get_height_shape
	ble	t5, zero, get_height_shape
	
	# Check bottom pixel
	mv	t0, t6
	addi	t1, t5, -1

	mv	a0, t0
	mv	a1, t1	
	call 	get_pixel
	beq	a0, zero, end_check_pixel
	
	# Check right pixel
	addi	t0, t6, 1
	mv	t1, t5

	mv	a0, t0
	mv	a1, t1	
	call 	get_pixel
	beq	a0, zero, end_check_pixel

	
	# Check bottom right pixel
	addi	t0, t6, 1
	addi	t1, t5, -1

	mv	a0, t0
	mv	a1, t1	
	call 	get_pixel
	beq	a0, zero, end_check_pixel

# Initialise getting information about vertical line
start_get_height_shape:
	# Save X and Y to a2 and a3
	mv 	a2, t5		# Y
	mv 	a3, t6		# X
	# Set counter of height
	li 	a4, 1
	# Set image height to a5
	la 	a5, height
	lw	a5, (a5)

# Get information about vertical line
get_height_shape:
	# Increment current Y
	addi	a2, a2, 1
	# Check if max height is reached, if so go to end
	beq	a2, a5, end_get_height_shape
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, a3
	mv	a1, a2
	call	get_pixel
	
	# If pixel is not black then go to end
	bnez	a0, end_get_height_shape
	# Increment height found
	addi	a4, a4, 1
	
	j get_height_shape

# Save results of get_height_shape
end_get_height_shape:
	# Set height of shape into s8
	mv	s8, a4
	# Store the Y value into s9
	addi	a2, a2, -1
	mv	s9, a2
	
	li	s7, 1

# Get the thickness of the vertical line
get_height_line_width_shape:
	# Check if left of image is reached, if so go to get width of shape
	beq	a3, zero, start_get_width_shape

	# Decrement current X
	addi	a3, a3, -1
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, a3
	mv	a1, a2
	call	get_pixel
	
	# If pixel is not black then go to end
	bnez	a0, start_get_width_shape
	# Increment height found
	addi	s7, s7, 1
	
	j get_height_line_width_shape

# Initialise getting information about horizontal line
start_get_width_shape:
	# Save X and Y to a2 and a3
	mv 	a2, t5		# Y
	mv 	a3, t6		# X
	# Set counter of width
	li 	a4, 1

# Get information about horizontal line
get_width_shape:
	# Check if left of image is reached, if so go to end
	beq	a2, zero, end_get_height_shape

	# Decrement current X
	addi	a3, a3, -1
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, a3
	mv	a1, a2
	call	get_pixel
	
	# If pixel is not black then go to end
	bnez	a0, end_get_width_shape
	# Increment width found
	addi	a4, a4, 1
	
	j 	get_width_shape
	
# Save results of get_width_shape
end_get_width_shape:
	# Set width of shape into s10
	mv	s10, a4
	# Store the X value into s11
	addi	a3, a3, 1
	mv	s11, a3
	
	# Check if shape is not 1 to prevent 1x2 shape
	li	s0, 1
	beq	s10, s0, end_check_pixel
	
	li	s6, 1
	
# Get the thickness of the horizontal line	
get_width_line_width_shape:
	# Check if max height (image height) is reached, if so continue
	beq	a2, a5, end_information_get

	# Increment current Y
	addi	a2, a2, 1
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, a3
	mv	a1, a2
	call	get_pixel
	
	# If pixel is not black then go to end
	bnez	a0, end_information_get
	# Increment height found
	addi	s6, s6, 1
	
	j get_width_line_width_shape

# Save all results and do checks for shape
end_information_get:
	# Check if height is twice the length of width, if not, invalid shape and go to next pixel
	li	s1, 2
	mul	s2, s10, s1
	bne 	s8, s2, end_check_pixel
	
	# Check if line thickness is the same, if not, invalid shape and go to next pixel
	bne	s7, s6, end_check_pixel
	
	# OLD wasn't suited for shape that are very close to each other
	# Check the top left pixel to ensure it is not a cube
	# mv	a0, s11
	# mv	a1, s9
	# call 	get_pixel
	# beqz	a0, end_check_pixel

# Check first rectangle (vertical height * vertical thickness)
check_first_rect:
	# Set flag to zero
	xor	a6, a6, a6

	# Set value of height rectangle of reverse L
	sub	a0, t6, s7	# X calculated by (X of starting point minus the thickness of the line)
	addi	a0, a0, 1
	mv	a1, t5		# Y of starting point
	mv	a2, t6		# X of starting point
	mv	a3, s9		# Y of top of shape
	j	check_rect

# Check second rectangle (horizontal width * horizontal thickness)
check_second_rect:
	# Set flag to one
	addi	a6, a6, 1

	# Set value of width rectangle of reverse L
	mv	a0, s11		# X of the left of shape
	mv	a1, t5		# Y of starting point
	mv	a2, t6		# X of starting point
	add	a3, t5, s6	# Y calculated by (Y of starting point plus the thickness of the line)
	addi	a3, a3, -1
	j	check_rect	
	
# Check rectangle taxes in
#	a0: x0
#	a1: y0
#	a2: x1
#	a3: y1
check_rect:
	# Set variable
	mv	s0, a0
	mv	s1, a1
	
	# To reset col if next row
	mv	s2, a0
	

# Loop over all pixels in the square between point 0 and point 1
check_rect_loop:
	# Increment X
	addi	s0, s0, 1
	
	# Check if end of rectangle is reached vertically, if so end check successfully
	bgt	s1, a3, end_check_rect_loop
	# Check if end of rectangle is reached horizontally, if so go to next row
	bgt	s0, a2, check_rect_loop_next_row
	
	# Move current X and Y into argument registers
	mv	a0, s0
	mv	a1, s1
	# Get pixel
	call 	get_pixel
	# Check if pixel is black, if not stop check and go to next pixel since this is not the shape
	bnez	a0, end_check_pixel
	
	# Iterate
	j	check_rect_loop

# If end is reacher (bgt s0, a2, ...)
check_rect_loop_next_row:
	# Reset X
	mv	s0, s2
	# Increment Y
	addi	s1, s1, 1
	
	# Iterate
	j	check_rect_loop

# Handle rectangle check finish
end_check_rect_loop:
	# Branch if flag is not set yet so second rectangle of reverse L is checked
	beqz	a6, check_second_rect
	# If flag is set so check rectangle has finished successfully twice, check lines
	
# Initialise bottom line check variables
start_check_bottom_line:
	call restore_parameters
	
	# Set starting point X
	addi	s0, t6, 1
	# Set starting point Y
	addi	s1, t5, -1
	# Set final point X
	sub	s2, t6, s10

# Check if the line under the shape is all non-black
check_bottom_line:
	# If  final point X is greater than starting point X, check next line
	bgt	s2, s0, start_check_right_line
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s2
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s2, s2, 1
	
	# Iterate
	j	check_bottom_line

# Initialise right line check variables	
start_check_right_line:
	call restore_parameters
	
	# Set starting point X
	addi	s0, t6, 1
	# Set starting point Y
	addi	s1, t5, -1
	# Set final point Y
	add	s2, t5, s8

# Check if the line right of the shape is all non-black
check_right_line:
	# If  starting point Y is greater than final point Y, check next line
	bgt	s1, s2, start_check_top_line
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s0
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s1, s1, 1
	
	# Iterate
	j	check_right_line

# Initialise top line check variables
start_check_top_line:
	call restore_parameters
	
	# Set starting point X
	sub	s0, t6, s7
	# Set starting point Y
	add	s1, t5, s8
	# Set final point X
	addi	s2, t6, 1
	
# Check if the line above the vertical bar is all non-black
check_top_line:
	# If  starting point X is greater than final point X, check next line
	bgt	s0, s2, start_check_left_line
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s0
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s0, s0, 1
	
	# Iterate
	j	check_top_line

# Initialise left line check variables
start_check_left_line:
	call	restore_parameters
	
	# Set starting point X
	sub	s0, t6, s10
	# Set starting point Y
	addi	s1, t5, -1
	# Set final point Y
	add	s2, t5, s7

# Check if the line left of the horizontal bar is all non-black
check_left_line:
	# If  starting point Y is greater than final point Y, check next line
	bgt	s1, s2, start_check_inner_top_line
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s0
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s1, s1, 1
	
	# Iterate
	j	check_left_line

# Initialise inner top line check variables
start_check_inner_top_line:
	call	restore_parameters
	
	# Set starting X
	sub	s0, t6, s10
	# Set starting Y
	add	s1, t5, s6
	# Set final point X
	sub	s2, t6, s7
	
# Check if the line above the horizontal bar (not intersecting with the vertical bar) is all non-black
check_inner_top_line:
	# If  starting point X is greater than final point X, check next line
	bgt	s0, s2, start_check_inner_left_line
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s0
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s0, s0, 1
	
	# Iterate
	j	check_inner_top_line

# Initialise inner left line check variables	
start_check_inner_left_line:
	call	restore_parameters
	
	# Set starting X
	sub	s0, t6, s7
	# Set starting Y
	add	s1, t5, s6
	# Set final point Y
	add	s2, t5, s8

# Check if the line left of the vertical bar (not intersecting with the horizontal bar) is all non-black
check_inner_left_line:
	# If  starting point Y is greater than final point Y, check next line
	bgt	s1, s2, shape_found
	
	# Move X and Y into argument registers for get_pixel
	mv	a0, s0
	mv	a1, s1
	call	get_pixel
	# If there is a black pixel the shape does not fit, stop checking and go to next pixel
	beqz	a0, end_check_pixel
	
	# Go to next pixel in line
	addi	s1, s1, 1
	
	# Iterate
	j	check_inner_left_line
	
# Print results (only reached if all checks have succeeded)
shape_found:
	# Print number found
	li	a7, 1
	mv	a0, s4
	ecall
	
	# Increment found
	addi	s4, s4, 1
	
	# Check if max of 50 was reached
	li	s6, 50
	bge	s7, s6, max_markers

	# Print leading text
	li	a7, 4
	la	a0, opening_text
	ecall

	# Print X coordinate
	li	a7, 1
	mv	a0, t6
	ecall
	
	# Print separator
	li	a7, 4
	la	a0, separator_text
	ecall
	
	# Get height since scanning from bottom to print Y correctly
	la 	s8, height
	lw	s8, (s8)
	
	# Subtract height from given Y to get Y from top
	sub	s8, s8, t5
	# Subtract 1 because Y is 0-based and normal image tools are 1-based indexed
	addi	s8, s8, -1
	
	# Print Y coordinate
	li	a7, 1
	mv	a0, s8
	ecall
	
	# Print separator
	li	a7, 4
	la	a0, closing_text
	ecall
	
# Get the next pixel in the image and reiterate from the start
end_check_pixel:
	# Increment pointer to next pixel
	addi	t6, t6, 1

	# Check if we have reached the end of the row (if x is less than image width go to check_pixel)
	la	t0, width
	lw	t0, (t0)
	blt	t6, t0, check_pixel

# When last X value is reached reset to 0 and increment Y, going to the next row
next_row:
	# Reset pointer to start of row
	mv	t6, zero

	# Increment pointer to next row
	addi	t5, t5, 1

	# Check if we have reached the end of the image (if y is less than image height go to check_pixel)
	la	t0, height
	lw	t0, (t0)
	blt	t5, t0, check_pixel

	# If this is reached x and y are both equal to width and height
	j	end_program
	
# Reset all parameters
restore_parameters:
	# Set registes to 0
	xor	t0, t0, t0
	xor	t1, t1, t1
	xor	t2, t2, t2
	xor	t3, t3, t3
	xor	t4, t4, t4
	# t5 and t6 are used to store height and width
	
	xor	s0, s0, s0
	xor	s1, s1, s1
	xor	s2, s2, s2
	xor	s3, s3, s3
	xor	s5, s5, s5
	# s6 =  X line thickness
	# s7 = Y line thickness
	# s8 = Y line length
	# s9 = Y top value of line
	# s10 = X line length
	# s11 = X left value of line
	
	# Set registers to image height
	la	t0, height
	lw	t1, 0(t0)
	
	# Set registers to image width
	la	t2, width
	lw	t3, 0(t2)
	
	ret

# Get pixel at x and y
#	a0 = x
#	a1 = y
# Return
#	a0 = rgb
get_pixel:
	ble	a0, zero, get_pixel_out_of_bounds
	ble	a1, zero, get_pixel_out_of_bounds
	
	la	t1, width
	lw	t1, (t1)
	bgt	a0, t1, get_pixel_out_of_bounds
	
	la	t1, height
	lw	t1, (t1)
	bgt	a1, t1, get_pixel_out_of_bounds

	# Get the pointer to the start of the image
	la 	t1, buffer
	# Move pointer to header info about pixel offset
	addi 	t1, t1, 10
	# Load pixel offset value into t2
	lw 	t2, (t1)
	
	# Reset t1 to start of bitmap
	la 	t1, buffer
	# Add the offset
	add 	t2, t1, t2	

	# Get the width in bytes of the image
	li 	t4, IMG_STRIDE
	# To get the pointer multiply bytes per row by the row number
	mul 	t1, a1, t4 	
	# Save column number to t3
	mv 	t3, a0		
	# Shift one left to multiply by 2
	slli 	a0, a0, 1
	# Add multiplied by two to the column number to get multiplied by 3, which is necessary because each pixel is 3 bytes so x * 3
	add 	t3, t3, a0	
	# Add the start address of the right row to the column number
	add 	t1, t1, t3	
	# Load the pixel address by adding the index to the offset
	add 	t2, t2, t1
	
	# Load the pixel values
	
	# Load B
	lbu	a0, 0(t2)	

	# Load G
	lbu 	t1, 1(t2)	
	slli 	t1, t1, 8
	or 	a0, a0, t1

	# Load R
	lbu 	t1, 2(t2)	
    	slli 	t1, t1, 16
	or 	a0, a0, t1
	
	ret
	
get_pixel_out_of_bounds:
	li	a0, 16777215
	ret
	
# Get pixel at x and y
#	a0 = x0
#	a1 = y0
# Return
#	a0 = rgb
check_line:
	# Get the pointer to the start of the image
	la 	t1, buffer
	# Move pointer to header info about pixel offset
	addi 	t1, t1, 10
	# Load pixel offset value into t2
	lw 	t2, (t1)
	
	# Reset t1 to start of bitmap
	la 	t1, buffer
	# Add the offset
	add 	t2, t1, t2	

	# Get the width in bytes of the image
	li 	t4, IMG_STRIDE
	# To get the pointer multiply bytes per row by the row number
	mul 	t1, a1, t4 	
	# Save column number to t3
	mv 	t3, a0		
	# Shift one left to multiply by 2
	slli 	a0, a0, 1
	# Add multiplied by two to the column number to get multiplied by 3, which is necessary because each pixel is 3 bytes so x * 3
	add 	t3, t3, a0	
	# Add the start address of the right row to the column number
	add 	t1, t1, t3	
	# Load the pixel address by adding the index to the offset
	add 	t2, t2, t1
	
	# Load the pixel values
	
	# Load B
	lbu	a0, 0(t2)	

	# Load G
	lbu 	t1, 1(t2)	
	slli 	t1, t1, 8
	or 	a0, a0, t1

	# Load R
	lbu 	t1, 2(t2)	
    	slli 	t1, t1, 16
	or 	a0, a0, t1
	
	ret
	
# Print error message for not found and exit
error_not_found:
	# Display error message
	li	a7, 4
	la	a0, error_not_found_message
	ecall

	j 	end_program

# Print error message for filetype and exit	
error_filetype:
	# Display error message
	li	a7, 4
	la	a0, error_filetype_message
	ecall

	j 	end_program

# Print error message for size (width x height) and exit	
error_size:
	# Display error message
	li	a7, 4
	la	a0, error_size_message
	ecall

	j 	end_program

# Print info for max markers reached and exit
max_markers:
	# Display error message
	li	a7, 4
	la	a0, max_markers_message
	ecall

	j 	end_program

# Exit program	
end_program:
	# exit
	li	a7, 10
	ecall	
