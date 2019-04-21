.data

# USED BY "get_file_name"
file_name_buffer:   	.space 40
enter_f_name_prompt: 	.asciiz "Entre o nome do arquivo a ser compilado: "
# USED BY "read_file_lines"
file_name: 						.asciiz "Code/Trabalho/sup.asm"
nada: 								.space 18
file_buffer: 					.space 20
file_buffer_length: 	.word 20
line_buffer:					.space 81
file_descriptor: 			.word 0
newline:      				.word '\n'
line:									.asciiz "linha: "

.text
	# get filename
	jal get_file_name
	
	move $a0, $v0
	la $a1, print_line
	jal read_file_lines
	
	# end program
	li $v0, 10
	syscall

# FUNCAO QUE PEGA O NOME DO ARQUIVO
get_file_name:
# returns: pointer to filename string

	# push to stack
	subi $sp, $sp, 12
	sw $a0, 0($sp)
	sw $a1, 4($sp)
	sw $v0, 8($sp)

	# prompt user to enter file name
	la $a0, enter_f_name_prompt
	li $v0, 4
	syscall

	# read file name
	la $a0, file_name_buffer
	li $a1, 40
	li $v0, 8
	syscall
	
	# replace '\n' with '\0'
	li $t1, '\n'									# load imediate '\n'
	get_fname_loop:								
	lb $t0, 0($a0)								# get char from filename
	addi $a0, $a0, 1							# point to next char
	bne $t0, $t1, get_fname_loop	# while char "= '\n'
	li $t0, '\0'									# load imediate '\0'
	sb $t0, -1($a0)								# replace '\n' with '\0'
	
	end_get_fname_loop:
	
	# pop from stack
	lw $a0, 0($sp)
	lw $a1, 4($sp)
	lw $v0, 8($sp)
	addi $sp, $sp, 12

	# return
	la $v0, file_name_buffer
	jr $ra

# FUNCAO TESTE QUE PRINTA A STRING INSERIDA EM $a0
print_line:
	# push to stack
	subi $sp, $sp, 12
	sw $t0,  0($sp)
	sw $a0,  8($sp)
	sw $v0, 12($sp)
	
	move $t0, $a0
	la $a0, line
	li $v0, 4
	syscall
	move $a0, $t0
	syscall
	la $a0, newline
	syscall
	
	# push to stack
	lw $t0,  0($sp)
	lw $a0,  8($sp)
	lw $v0, 12($sp)
	addi $sp, $sp, 12
	
	jr $ra # return
		
# FUNCAO QUE LE UM ARQUIVO LINHA A LINHA E EXECUTA A FUNCAO DADA EM CADA LINHA
read_file_lines:
# $a0: nome do arquivo
# $a1: funcao a ser executada
# returns: void

	# push registers to the stack
	subi $sp, $sp, 44
	sw $a0, 0($sp)				# used for function calls
	sw $a1, 4($sp)				# used for function calls
	sw $v0, 8($sp)				# used for system calls
	sw $t0, 12($sp)				# used for file buffer pointer
	sw $t1, 16($sp)				# used for pointer to end of file buffer
	sw $t2, 20($sp)				# used read/write bytes from file buffer to string buffer
	sw $t3, 24($sp)				# used to store chars for comparison and insertion
	sw $t4, 28($sp)				# used to store end of buffer flag
	sw $t5, 32($sp)				# used to store EOF flag
	sw $s0, 36($sp)				# used to store file descriptor
	sw $s1, 40($sp)				# used for line buffer pointer
	sw $ra, 44($sp)				# used for function calls

	# open file (do once)
	li   $v0, 13       						# system call for open file
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
	
	###### CALL FUNCTION GIVEN, USING LINE BUFFER AS ARGUMENT
	lw $t3, 4($sp)						# get function address
	la $a0, line_buffer				# set up line buffer as argument
	la $ra, return_from_call	# set up return address
	jr $t3										# call function
	return_from_call:					# return
	
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

	# pop registers from the stack
	lw $a0, 0($sp)				# used for function calls
	lw $a1, 4($sp)				# used for function calls
	lw $v0, 8($sp)				# used for system calls
	lw $t0, 12($sp)				# used for file buffer pointer
	lw $t1, 16($sp)				# used for pointer to end of file buffer
	lw $t2, 20($sp)				# used read/write bytes from file buffer to string buffer
	lw $t3, 24($sp)				# used to store chars for comparison and insertion
	lw $t4, 28($sp)				# used to store end of buffer flag
	lw $t5, 32($sp)				# used to store EOF flag
	lw $s0, 36($sp)				# used to store file descriptor
	lw $s1, 40($sp)				# used for line buffer pointer
	lw $ra, 44($sp)				# used for function calls
	addi $sp, $sp, 44
	
	jr $ra
	# return

# END OF FUNCTION

# read file code from https://stackoverflow.com/questions/37469323/assembly-mips-read-text-from-file-and-buffer/37505359#37505359
