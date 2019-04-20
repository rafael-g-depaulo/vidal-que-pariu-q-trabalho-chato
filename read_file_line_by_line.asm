.data
file_name: 					.asciiz "Code/Trabalho/test.txt"
nada: 							.space 18
file_buffer: 				.space 20
file_buffer_length: .word 20
line_buffer:				.space 81
file_descriptor: 		.word 0
newline:      			.word '\n'
line:								.asciiz "linha: "

.text
# open file (do once)
	la $a0, file_name

	li   $v0, 13       						# system call for open file
	la   $a0, file_name						# input file name
	li   $a1, 0        						# flag for reading
	li   $a2, 0        						# mode is ignored
	syscall            						# open a file 
	move $s0, $v0      						# save the file descriptor 
	sw $s0, file_descriptor 			# save file descriptor on memory
	la $s1, line_buffer 					# get start of line buffer ($s1 = line_buffer)

# read 20 characters from file ####
get_line_chars:
	li   $v0, 14       						# system call for reading from file
	move $a0, $s0      						# file descriptor 
	la   $a1, file_buffer					# address of buffer from which to read
	lw   $a2, file_buffer_length	# hardcoded buffer length
	syscall            						# read from file

# if read less than buffer_length chars
	slt $t5, $v0, $a2 						# if read less than buffer_length chars, finished file
	beq $t5, $zero, not_EOF				# set a flag to end procedure after processing line
	
	add $a1, $a1, $v0 						# end of characters read from file
	li $t3, '\n'									# load '\n'
	sb $t3, 0($a1)								# add a '\n' at the end of the buffer
# end_if

not_EOF:
	# put file buffer content into line buffer (up to \n)
	# if current byte not '\n', put into line buffer
	la $t0, file_buffer 					# $t0 = inicio do file buffer
	lw $t1, file_buffer_length  	# tamanho do buffer
	add $t1, $t1, $t0							# $t1 = final do buffer
	
	li $t3, '\n'									# $t3 = '\n'

# move string from buffer to line_buffer	
move_char_buffer2line:
	lbu $t2, 0($t0)								# get cuttent byte
	beq $t2, $t3, line_done				# if found '\n', end line and proccess it
	
	# if not '\n', write to line buffer
	sb $t2, 0($s1)									# write to current char in line
	addi $s1, $s1, 1								# increase line buffer pointer ($s1)
	addi $t0, $t0, 1								# increase file buffer pointer ($t0)
	slt $t4, $t0, $t1								# if at the end of buffer
	beq $t4, $zero, get_line_chars	# read next line
	
	j move_char_buffer2line					# read more chars into buffer
	
	# if '\n', process line
line_done:

	li $t3, '\0'									 # write '\0' to end line
	sb $t3, 0($s1)								 # write '\0' to end line
	
	###### (TODO) process line
	# printando pra tela como teste
	la $a0, line
	li $v0, 4
	syscall
	la $a0, line_buffer
	syscall
	la $a0, newline
	syscall
	###### (TODO) process line

	###### ADD REST OF BUFFER TO NEXT LINE & RESET LINE POINTER
	# $t0: buffer pointer
	# $s1: line buffer pointer
	addi $t0, $t0, 1 						# current $t0 is '\n', move to next one
	la $s1, line_buffer					# reset line pointer to start of buffer
	write_buffer_to_line_loop:
	beq $t0, $t1, finished_with_buffer	# if finished writing from buffer, leave loop
	lb $t3, 0($t0)							# get char from buffer
	sb $t3, 0($s1)							# write char to line buffer
	addi $t0, $t0, 1						# increase buffer pointer
	addi $s1, $s1, 1						# increase line buffer pointer
	j write_buffer_to_line_loop
	finished_with_buffer:
	
	# check $t5. if == 1, EOF reached, dont get another line
	beq $t5, $zero, get_line_chars 	# get next line if not at EOF
	
	# closing file
	lw $a0, file_descriptor  	# close file
	li $v0, 16								# close file
	syscall										# close file
	
	# end program
	li $v0, 10
	syscall
	
# read file code from https://stackoverflow.com/questions/37469323/assembly-mips-read-text-from-file-and-buffer/37505359#37505359
