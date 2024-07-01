.eqv	max_markers		50		# maximum number of markers
.eqv	img_buffer		230400	# bitmap pixel buffer size
.eqv	img_header		54		# bitmap header size
.eqv	img_width		320		# bitmap width
.eqv	img_height		240		# bitmap height
.eqv	img_stride		960		# bitmap stride (in bytes)
.data
.align	2
header:		.space	img_header
.align	2
buffer:		.space	img_buffer
.align 	0
filename:	.asciz	"example_markers.bmp"
found_pre:	.asciz	"Marker #9 found at: ("
found_mid:	.asciz	", "
found_end:	.asciz	")\n"
.text
# load the bitmap
	li		a7, 1024
	la		a0, filename
	mv		a1, zero
	ecall
	mv		t6, a0	# file descriptor preserved in t6
	li		a7, 63
	la		a1, header
	li		a2, img_header
	ecall
	mv		a0, t6
	la		a1, buffer
	li		a2, img_buffer
	ecall
	li		a7, 57
	mv		a0, t6
	ecall
	
	call	find_markers
	
# exit
	li		a7, 10
	ecall
	
# compute the address of the pixel
# a0:ptr_pixel(a0:x, a1:y)
ptr_pixel:
	la		t6, buffer		# Loads pointer to buffer
	li		t0, 3			# Set t0 to 3
	mul		t0, t0, a0		# Multiply t0 by x to get the offset from left
	add		t6, t6, t0		# Add the offset to the buffer pointer
	li		t0, img_height	# Set t0 to img_height
	sub		t0, t0, a1		# Subtract y from t0 because bitmap images read from bottom to top
	addi	t0, t0, -1		# Subtract 1 from t0 to get the offset from the top
	li		t1, img_stride	# Set t1 to img_stride
	mul		t0, t0, t1		# Multiply t0 by t1 to get the offset from the top
	add		a0, t6, t0		# Add the offset to the buffer pointer
	ret
	
	
# a0: get_pixel(a0:ptr)
# returns an rgbx pixel packed as a word
get_pixel:
	lbu		t0, 2(a0)
	slli	t0, t0, 16
	lbu		t1, 1(a0)
	slli	t1, t1, 8
	lbu		t2, 0(a0)
	or		t0, t0, t1
	or		a0, t0, t2
	ret
	
# goes through the entire image, looking for markers of type 9
# a0:find_markers();
# returns the number of markers found
find_markers:
	addi	sp, sp, -16
	sw		ra, 0(sp)
	sw		s0, 4(sp)
	sw		s1, 8(sp)
	sw		s2, 12(sp)
	.eqv	find_x	s0
	.eqv	find_y	s1
	.eqv	found	s2
	mv		found, zero
	mv		find_y, zero
find_for_y:
	mv		find_x, zero
find_for_x:
	mv		a0, find_x
	mv		a1, find_y
	call	check_marker
	beqz	a0, find_for_x_skip
	# printf("Marker #9 found at: (%i, %i)", x, y);
	li		a7, 4
	la		a0, found_pre
	ecall
	li		a7, 1
	mv		a0, find_x
	ecall
	li		a7, 4
	la		a0, found_mid
	ecall
	li		a7, 1
	mv		a0, find_y
	ecall
	li		a7, 4
	la		a0, found_end
	ecall
	addi	found, found, 1		# found++
find_for_x_skip:
	add		find_x, find_x, a1	# x += (found ?? skipped).width
	# for (x = 0; x < img_width - 2; ++x)
	li		t0, img_width
	addi	t0, t0, -2
	addi	find_x, find_x, 1
	blt		find_x, t0, find_for_x	
	# for (y = 0; y < img_height - 2; ++y)
	li		t0, img_height
	addi	t0, t0, -2
	addi	find_y, find_y, 1
	blt		find_y, t0, find_for_y
	# return found
	lw		ra, 0(sp)
	lw		s0, 4(sp)
	lw		s1, 8(sp)
	lw		s2, 12(sp)
	addi	sp, sp, 16
	ret

# checks whether (x, y) is the top-left corner of a marker	
# (a0,a1,a2):check_marker(a0:x, a1:y)
# returns a tuple in 3 registers:
#  a0: line thickness, or 0 on error
#  a1: width, or skip width on error
#  a2: height, or 0 on error
check_marker:
	addi	sp, sp, -28
	sw		ra, 0(sp)
	sw		s0, 4(sp)
	sw		s1, 8(sp)
	sw		s2, 12(sp)
	sw		s3, 16(sp)
	sw		s4, 20(sp)
	sw		s5, 24(sp)
	.eqv	mark_x		s0	# marker x
	.eqv	mark_y		s1	# marker y
	.eqv	h_line		s2	# horizontal line
	.eqv	h_line_th	s3	# horizontal line thickness
	.eqv	v_line		s4	# vertical line
	.eqv	v_line_th	s5	# vertical line thickness
	mv		h_line, zero
	mv		v_line, zero
	mv		mark_x, a0
	mv		mark_y, a1
	#
	# marker detection logic
	#
	# if (get_pixel(x, y) != 0) return 0;
	mv		a0, mark_x
	mv		a1, mark_y
	call	ptr_pixel
	call	get_pixel
	bnez	a0, check_marker_fail
	#
	mv		a0, mark_x
	mv		a1, mark_y
	call	scan_x
	mv		h_line, a0		# hLine = scan_x(x, y);
	mv		a0, mark_x
	mv		a1, mark_y
	call	scan_y
	mv		v_line, a0		# vLine = scan_y(x, y);
	# if (hLine != (vLine >> 1)) return -1;
	srli	t0, v_line, 1
	bne		h_line, t0, check_marker_fail
	# if (verify_rect(x0, y0 - 1, x0 + hLine, y0 - 1) != 0) return 0;
	mv		a0, mark_x,
	addi	a1, mark_y, -1
	add		a2, mark_x, h_line
	mv		a3, a1
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	# if (verify_rect(x - 1, y, x - 1, y + vLine) != 0) return 0
	addi	a0, mark_x, -1
	mv		a1, mark_y
	mv		a2, a0
	add		a3, mark_y, v_line
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	#
	mv		a0, mark_x
	add		a1, mark_y, v_line
	addi	a1, a1, -1
	call	scan_x
	mv		h_line_th, a0	# hTLine = scan_x(x, y + vLine - 1);
	# if (hTLine >= hLine) return -1;
	bge		h_line_th, h_line, check_marker_fail
	#
	add		a0, mark_x, h_line
	addi	a0, a0, -1
	mv		a1, mark_y
	call	scan_y
	mv		v_line_th, a0	# vTLine = scan_y(x + hLine - 1, y0);
	# if (vTLine >= vLine) return -1;
	bge		v_line_th, v_line, check_marker_fail
	# if (vTLine != hTLine) return -1;
	bne		v_line_th, h_line_th, check_marker_fail
	# if (verify_rect(x + hLine, y, x + hLine, y + vTLine) != 0) return 0
	add		a0, mark_x, h_line
	mv		a1, mark_y
	mv		a2, a0
	add		a3, mark_y, v_line_th
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	# if (verify_rect(x, y + vLine, x + hTLine, y + vLine) != 0) return 0
	mv		a0, mark_x
	add		a1, mark_y, v_line
	add		a2, mark_x, h_line_th
	mv		a3, a1
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	# if (verify_rect(x + hTLine, y + vTLine, x + hLine, y + vTLine) != 0) return 0
	add		a0, mark_x, h_line_th
	add		a1, mark_y, v_line_th
	add		a2, mark_x, h_line
	mv		a3, a1
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	# if (verify_rect(x + hTLine, y + vTLine, x + hTLine, y + vLine) != 0) return 0
	add		a0, mark_x, h_line_th
	add		a1, mark_y, v_line_th
	mv		a2, a0
	add		a3, mark_y, v_line
	mv		a4, zero
	call	verify_rect
	bnez	a0, check_marker_fail
	# if (verify_rect(x, y, x + hLine - 1, y + vTLine - 1) != (vTLine * hLine)) return 0
	mv		a0, mark_x
	mv		a1, mark_y
	add		a2, mark_x, h_line
	addi	a2, a2, -1
	add		a3, mark_y, v_line_th
	addi	a3, a3, -1
	mv		a4, zero
	call	verify_rect
	mul		t0, v_line_th, h_line
	bne		t0, a0, check_marker_fail
	# if (verify_rect(x, y + vTLine, x + hTLine, y + vLine) != ((vLine - vTLine) * hTLine)) return 0
	mv		a0, mark_x
	add		a1, mark_y, v_line_th
	add		a2, mark_x, h_line_th
	add		a3, mark_y, v_line
	mv		a4, zero
	call	verify_rect
	sub		t0, v_line, v_line_th
	mul		t0, t0, h_line_th
	bne		t0, a0, check_marker_fail
	# return (vTLine, vLine, hLine);
	mv		a0, v_line_th
	mv		a1, h_line
	mv		a2, v_line
	j		check_marker_done
check_marker_fail:
	mv		a0, zero
	mv		a1, h_line
	mv		a2, v_line
check_marker_done:
	lw		ra, 0(sp)
	lw		s0, 4(sp)
	lw		s1, 8(sp)
	lw		s2, 12(sp)
	lw		s3, 16(sp)
	lw		s4, 20(sp)
	lw		s5, 24(sp)
	addi	sp, sp, 28
	ret

	
# a0:scan(a0:x, a1:y, a2:step)
# scans the string for either black or non-black color
# depending on mode, given a fixed byte step (pixel)
# and an initial pair of coordinates to get the pixel ptr
# returns the number of matching pixels along the path
scan:
	addi	sp, sp, -16
	sw		ra, 0(sp)
	sw		s0, 4(sp)
	sw		s1, 8(sp)
	sw		s2, 12(sp)
	.eqv	scan_ptr	s0
	.eqv	scan_step	s1
	.eqv	scan_count	s2
	call	ptr_pixel
	mv		scan_ptr, a0
	mv		scan_step, a2
	mv		scan_count, zero
scan_solid:
	mv		a0, scan_ptr
	call	get_pixel
	bnez	a0, scan_break
	addi	scan_count, scan_count, 1
	add		scan_ptr, scan_ptr, scan_step
	j		scan_solid
scan_break:
	mv		a0, scan_count
	lw		ra, 0(sp)
	lw		s0, 4(sp)
	lw		s1, 8(sp)
	lw		s2, 12(sp)
	addi	sp, sp, 16
	ret
# a0:scan_x(a0:x, a1:y)
scan_x:
	li		a2, 3
	j		scan
# a0:scan_y(a0:x, a1:y)
scan_y:
	li		a2, -img_stride
	j		scan


# a0:verify_rect(a0:x0, a1:y0, a2:x1, a3:y1, a4:color)
# counts the number of desired pixels within the rectangle
verify_rect:
	addi	sp, sp, -40
	sw		ra, 0(sp)
	sw		s0, 4(sp)
	sw		s1, 8(sp)
	sw		s2, 12(sp)
	sw		s3, 16(sp)
	sw		s4, 20(sp)
	sw		s5, 24(sp)
	sw		s6, 28(sp)
	sw		s7, 32(sp)
	sw		s8, 36(sp)
	.eqv	rect_x0		s0
	.eqv	rect_x1		s1
	.eqv	rect_y0		s2
	.eqv	rect_y1		s3
	.eqv	rect_color	s4
	.eqv	rect_y		s5
	.eqv	rect_x		s6
	.eqv	rect_pixel	s7
	.eqv	rect_count	s8
	mv		rect_count, zero
	mv		rect_x0, a0
	mv		rect_y0, a1
	mv		rect_x1, a2
	mv		rect_y1, a3
	mv		rect_color, a4
	bltz	rect_x0, verify_out_of_bounds
	bltz	rect_y0, verify_out_of_bounds
	li		t0, img_width
	li		t1, img_height
	bge		rect_x1, t0, verify_out_of_bounds
	bge		rect_y1, t1, verify_out_of_bounds
	mv		rect_y, rect_y0
verify_for_y:
	mv		rect_x, rect_x0
verify_for_x:
	mv		a0, rect_x
	mv		a1, rect_y
	call	ptr_pixel
	call	get_pixel
	bne		a0, rect_color, verify_skip
	addi	rect_count, rect_count, 1
verify_skip:
	addi	rect_x, rect_x, 1
	ble		rect_x, rect_x1, verify_for_x
	addi	rect_y, rect_y, 1
	ble		rect_y, rect_y1, verify_for_y
verify_return:
	mv		a0, rect_count
	lw		ra, 0(sp)
	lw		s0, 4(sp)
	lw		s1, 8(sp)
	lw		s2, 12(sp)
	lw		s3, 16(sp)
	lw		s4, 20(sp)
	lw		s5, 24(sp)
	lw		s6, 28(sp)
	lw		s7, 32(sp)
	lw		s8, 36(sp)
	addi	sp, sp, 40
	ret
verify_out_of_bounds:
	sub		t0, rect_x1, rect_x0
	sub		t1, rect_y1, rect_y0
	mul		rect_count, t0, t1
	j		verify_return