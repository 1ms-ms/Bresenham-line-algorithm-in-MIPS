.eqv	pHeader	0
.eqv	filesize 4
.eqv	pImg	8
.eqv	width	12
.eqv	height	16
.eqv	linesbytes 20

.eqv	bi_imgoffset  10
.eqv	bi_imgwidth   18
.eqv	bi_imgheight  22

.eqv	max_file_size 2048 	#524288 for blank.bmp

	.data
filename:		.asciiz "black32x32.bmp"
resultfile:		.asciiz "result.bmp"
color_err:		.asciiz "Incorrect color - should be 0 or 1"
save_error_mess:	.asciiz "Error occured while saving the file"
read_error_mess:	.asciiz "Error occured while reading the file"


		.align	4
descriptor:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0

filebuf:	.space max_file_size

	.text
main:
	la $a0, filename
	la $a1, descriptor
	la $t8, filebuf
	sw $t8, pHeader($a1)
	li $t8, max_file_size
	sw $t8, filesize($a1)
	jal read_bmp_file
	
	
    	la   $t0, descriptor
    	li   $a0, 11 	#cx
    	li   $a1, 30 	#cy
    	li   $t1, 1  	#color
    	li   $a2, 13 	#x
    	li   $a3, 4	#y
    	
    	
line_to:

# |register|   variable  |
# | a0     |       cx    |
# | a1     |       cy    |	
# | a2     |       x     |
# | a3     |       y     |
# | t2     |    dx - dy  |   
# | t3     |   ai        |
# | t4     |   bi        |
# | t5     |   d	 |
# | s2     | dx = x-cx   |
# | s3	   | dy = y-cy   |	   	
# | s4     |   xi        |
# | s5     |   yi        |
	
	sub $s2, $a2, $a0 #s2 = s0 - a0
	sub $s3, $a3, $a1 #s3 = s1 - a1
#if (dx < 0) { xi = 1 } else { xi = -1}
	bltz $s2,  if_1_then 
	if_1_else:
   	 addi $s4,$0, 1
    	 j if_1_exit
	if_1_then:
    	addi $s4,$0, -1
    	addi $t6,$0, -1		#dx=-dx
	mult $t6, $s2
	mflo $s2
 	if_1_exit:

#if (dy < 0) { yi = 1 } else { yi = -1}
	bltz $s3, if_2_then 
	if_2_else:
    	addi $s5,$0, 1
    	 j if_2_exit
	if_2_then:
    	addi $s5,$0, -1
    	addi $t6,$0, -1		#dy=-dy
	mult $t6, $s3
	mflo $s3
	if_2_exit:

	sub $t2, $s3, $s2 #   err = dy - dx

	
	jal set_next_pixel	#set pixel bo (cx,cy)
	
	
	bgt $t2, $zero, if_then		#first if dx<=dy
	ble $t2, $zero, if_else 	#second if dx>dy
	
	
if_else:	#first if dx<=dy
	sll $t3, $t2, 1 #(dy-dx)*2
	sll $t4, $s3, 1
	sub $t5, $t4, $s2
	jal loop
	
if_then:	#second if dx>dy
	sub $t2, $0,$t2 #0-(dy-dx)=dx-dy
	sll $t3, $t2, 1	#(dx-dy)*2
	sll $t4, $s2, 1 #dy*2
	sub $t5, $t4, $s3	#d=bi-dx
	jal loop1


loop:
	beq $a0, $a2, save  #while cx != x
	bgez $t5, if  #d >= 0
	ble $t5, $zero, else	#d<0
	
if:
	add $a0, $a0, $s4 	#cx += xi;
	add $a1, $a1, $s5	#cy += yi;
	add $t5, $t5, $t3	#d += ai;
	jal set_next_pixel
	jal loop
else:
	add $t5, $t5, $t4	#d += bi;
	add $a0, $a0, $s4	#cx += xi;
	jal set_next_pixel
	jal loop
	#########################
loop1:
	beq $a1, $a3, save  #while cy != y
	bgez $t5, if1  #d >= 0
	ble $t5, $zero, else1
	
if1:
	add $a0, $a0, $s4
	add $a1, $a1, $s5
	add $t5, $t5, $t3
	jal set_next_pixel
	j loop1
else1:
	add $t5, $t5, $t4
	add $a1, $a1, $s5
	jal set_next_pixel
	j loop1
	#########################
save:
	la $a0, resultfile
	la $a1, descriptor
	jal save_bmp_file
	li $v0, 10
	syscall
set_next_pixel:
	move $t7, $a0		#move a0 to t7
	move $s0, $a1		#move a1 to s0
	lw $t8, linesbytes($t0)
	mul $t8, $t8, $s0   # $t0 offset of the beginning of the row
	
	sra $t9, $t7, 3	    # pixel byte offset within the row
	add $t8, $t8, $t9   # pixel byte offset within the image
	
	lw $t9, pImg($t0)
	add $t8, $t8, $t9   # address of the pixel byte
	
	lb $t9, 0($t8)
	
	and $t7, $t7, 0x7   # pixel offset within the byte
	li $t6, 0x80
	srlv $t6, $t6, $t7  # mask on the position of pixel
	
      	j set_color	#set to chosen color
	
set_color:
	addi $v1, $zero, 1
	blt $t1, $zero, print_color_err		# if a3 < 0, then error
	bgt $t1, $v1, print_color_err	#if a3 > 1, then error
	beq $t1,$v1, white 	# if a3 = 1, then white
      	beq $t1,$zero, black 	# if a3 = 0, then black
      	sw $t1, 0($sp)
      	
      
black:
	xor $t9, $t9, $t6    # set proper pixel to 0 (black)
	sb $t9, 0($t8)
	jr $ra
white:
	or $t9, $t9, $t6    # set proper pixel to 1 (white)
	sb $t9, 0($t8)
	jr $ra
print_color_err:
	li $v0, 4
	la $a0, color_err
	syscall
	li $v0, 10
	syscall

read_bmp_file:
	# $a0 - file name 
	# $a1 - file descriptor
	#	pHeader - contains pointer to file buffer
	#	filesize - maximum file size allowed
	move $t8, $a1
	li $a1, 0
	li $a2, 0
	li $v0, 13 # open file
	syscall
	# check for errors: $v0 < 0
	
	move $a0, $v0
	bltz $v0, read_err 
	lw $a1, pHeader($t8)
	lw $a2, filesize($t8)
	li $v0, 14
	syscall
	
	sw $v0, filesize($t8)  # actual size of bmp file

	li $v0, 16 # close file
	syscall

	lhu $t9, bi_imgoffset($a1)
	add $t9, $t9, $a1
	sw $t9, pImg($t8)
	
	lhu $t9, bi_imgwidth($a1)
	sw $t9, width($t8)
	
	lhu $t9, bi_imgheight($a1)
	sw $t9, height($t8)
	
	# number of words in a line: (width + 31) / 32
	# number of bytes in a line: ((width + 31) / 32) * 4
	lw $t9, width($t8)
	add $t9, $t9, 31
	sra $t9, $t9, 5 # t1 contains number of words
	sll $t9, $t9, 2
	sw $t9, linesbytes($t8)
	jr $ra
read_err:
	li $v0, 4
	la $a0, read_error_mess
	syscall
	li $v0, 10
	syscall

save_bmp_file:
	# $a0 - file name 
	# $a1 - file descriptor
	#	pHeader - contains pointer to file buffer
	#	filesize - maximum file size allowed
	move $t8, $a1
	li $a1, 1  # write
	li $a2, 0
	li $v0, 13 # open file
	syscall
	# check for errors: $v0 < 0
	bltz $v0, save_err
	move $a0, $v0
	lw $a1, pHeader($t8)
	lw $a2, filesize($t8)
	li $v0, 15
	syscall
	
	li $v0, 16 # close file
	syscall

	jr $ra
save_err:
	li $v0, 4
	la $a0, save_error_mess
	syscall
	li $v0, 10
	syscall
