.data
# USED BY "get_label_use"
label_use_str:				.space 	40

label_to_add1:				.asciiz "my_label"
label_to_add2:				.asciiz "my_label2"

# USED BY "get_label_dec"
label_dec_str:				.space 	40

# USED BY "insert_label"
label_list:						.word 	0	# ponteiro para o primeiro elemento da lista
label_list_end:				.word 	0	# ponteiro para o último elemento da lista

# USED BY "get_file_name"
file_name_buffer:   	.space 	40
enter_f_name_prompt: 	.asciiz "Entre o nome do arquivo a ser compilado: "

# USED BY "read_file_lines"
file_buffer: 					.space 	20
file_buffer_length: 	.word 	20
line_buffer:					.space 	80
file_descriptor: 			.word 	0
newline:      				.word 	'\n'
line:									.asciiz	"linha: "
lineend:							.asciiz "linha acabou."

.text
	# # get filename
	# jal get_file_name
	
	# # print lines test
	# move $a0, $v0
	# la $a1, print_line
	# jal read_file_lines
	
	# # count lines test
	# move $a0, $v0
	# la $a1, count_lines
	# li $a2, 0
	# jal read_file_lines

	# # print return value
	# move $a0, $v0
	# li $v0, 1
	# syscall

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
	lbu $t0, 0($a0)								# get char from filename
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

# FUNCAO DE TESTE QUE CONTA AS LINHAS DO AQUIVO
count_lines:
	# a0, linha
	# a1, counter
	addi $v0, $a1, 1
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
	la $a0, lineend
	syscall
	la $a0, newline
	syscall
	
	# push to stack
	lw $t0,  0($sp)
	lw $a0,  8($sp)
	lw $v0, 12($sp)
	addi $sp, $sp, 12
	
	jr $ra # return

# FUNCAO QUE LE UMA STRING, CHECA SE NELA TEM UMA LABEL SENDO USADA, E RETORNA O VALOR DA LABEL, E UM PONTEIRO PARA LOGO APÓS O USO DELA
#### UNTESTED ################
#### UNTESTED ################
#### UNTESTED ################
get_label_use:
# $a0: ponteiro para a string (linha)
# $v0: valor da label (0 se não achou)
# $v1: ponteiro para o próximo char depois do último caracter da label na string recebida em $a1

	# push to stack
	subi $sp, $sp, 40
	sw $a0,  0($sp)					# used to navigate the line string given as argument
	sw $a1,  4($sp)					# used to call str_compare
	sw $s0,  8($sp)					# used to traverse label_list
	sw $s1, 12($sp)					# used to store pointer to next char after end of label in line string
	sw $t0, 16($sp)					# used as a ponter to the write buffer, to construct the label being read
	sw $t1, 20($sp)					# used to store chars for comparison
	sw $t2, 24($sp)					# used as flag in comparisons of chars
	sw $t3, 28($sp)					# used to store lower bound immediates for char comparison
	sw $t4, 32($sp)					# used to store upper bound immediates for char comparison
	sw $ra, 36($sp)					# used for function calls

	la $t0, label_use_str		# set up write buffer pointer

	# navigate the line until a non ',', non whitespace char appears
	glu_loop1:
	lbu $t1, 0($a0)						# read char
	addi $a0, $a0, 1					# increase pointer
	beq $t1, ',' , glu_loop1	# if whitespace, keep looking
	beq $t1, ' ' , glu_loop1	# if whitespace, keep looking
	beq $t1, '\t', glu_loop1	# if whitespace, keep looking
	beq $t1, '\n', glu_loop1	# if whitespace, keep looking
	# if reached here, found first char of label.
	sb $t1, 0($t0)						# write first char to buffer
	addi $t0, $t0, 1					# update write pointer

	# now add the next chars into buffer, until a non-valid char is found
	glu_loop:
	lbu $t1, 0($a0)					# read char from line

	# if char is valid (a-zA-Z0-9_%$) write to label buffer
		# valid symbols
	beq $t1, '_', glu_is_valid
	beq $t1, '$', glu_is_valid
	beq $t1, '%', glu_is_valid	
		# if 0-9
	li $t3, '0'
	li $t4, '9'
	slt $t2, $t1, $t3		# if char is less than '0'
	bne $t2, $zero, glu_not_numeric
	slt $t2, $t4, $t1		# if '9' is less than char
	bne	$t2, $zero, glu_not_numeric
	j glu_is_valid			# if got here, is a number (and therefore valid)
	glu_not_numeric:
		# if A-Z	
	li $t3, 'A'
	li $t4, 'Z'
	slt $t2, $t1, $t3		# if char is less than 'A'
	bne $t2, $zero, glu_not_upcase
	slt $t2, $t4, $t1		# if 'Z' is less than char
	bne	$t2, $zero, glu_not_upcase
	j glu_is_valid			# if got here, is a number (and therefore valid)
	glu_not_upcase:
		# if a-z	
	li $t3, 'a'
	li $t4, 'z'
	slt $t2, $t1, $t3		# if char is less than 'a'
	bne $t2, $zero, glu_not_downcase
	slt $t2, $t4, $t1		# if 'z' is less than char
	bne	$t2, $zero, glu_not_downcase
	j glu_is_valid			# if got here, is a number (and therefore valid)
	glu_not_downcase:

	j glu_isnt_valid		# if got here, isnt a valid char

	# if is valid char
	glu_is_valid:
	sb $t1, 0($t0)		# write char to buffer
	addi $t0, $t0, 1	# increase write buffer pointer
	addi $a0, $a0, 1	# increase input string pointer
	j glu_loop				# read next char

	# else (is invalid char) finish label
	glu_isnt_valid:
	sb $zero, 0($t0)	# add '\0' at the end of buffer
	move $s1, $a0			# save pointer to after label ended

	# now look for which label it is in the list
	# OBS: it's in format pointer_to_next(4)|address(4)|label_string(X)
	la $s0, label_list	# get first element in label list
	la $a1, label_use_str						# pointer to label found
	find_label_loop:
	beq $s0, $zero, glu_l_ended			# if current list element is null
	addi $a0, $s0, 8								# pointer to current label in list
	jal str_compare									# check if the strings have the same value
	bne $v0, $zero, glu_found_label	# if found a match, got the right label
	# if got here, not found yet
	lw $s0, 0($s0)			# get next list element
	j find_label_loop		# check next list element

	# if got here, then the str in $t0 is the same as the label in $s0+8
	glu_found_label:
	lw $v0, 4($s0)	# get label address value
	move $v1, $s1		# get pointer to after label_str ended in line
	j glu_pop_and_return

	# reached the end of label_list and no match was found
	glu_l_ended:
	li $v0, 0

	# pop from stack & return
	glu_pop_and_return:
	lw $a0,  0($sp)					# used to navigate the line string given as argument
	lw $a1,  4($sp)					# used to call str_compare
	lw $s0,  8($sp)					# used to traverse label_list
	lw $s1, 12($sp)					# used to store pointer to next char after end of label in line string
	lw $t0, 16($sp)					# used as a ponter to the write buffer, to construct the label being read
	lw $t1, 20($sp)					# used to store chars for comparison
	lw $t2, 24($sp)					# used as flag in comparisons of chars
	lw $t3, 28($sp)					# used to store lower bound immediates for char comparison
	lw $t4, 32($sp)					# used to store upper bound immediates for char comparison
	lw $ra, 36($sp)					# used for function calls
	subi $sp, $sp, 40

	jr $ra

# FUNCAO QUE COMPARA 2 STRINGS E CHECA SE SÃO IGUAIS
str_compare:
# $a0: ponteiro para o início da string 1
# $a1: ponteiro para o início da string 2
# $v0: 1 se forem iguais, 0 se não forem

	# push to stack
	subi $sp, $sp, 16
	sw $a0, 0 ($sp)			# used as a pointer to string1
	sw $a1, 4 ($sp)			# used as a pointer to string2
	sw $t0, 8 ($sp)			# used to store a temp char from string1
	sw $t1, 12($sp)			# used to store a temp char from string2

	# get chars
	str_compare_loop:
	lbu $t0, 0($a0)						# read c1 from str1
	lbu $t1, 0($a1)						# read c2 from str1
	bne $t0, $t1, not_equal		# if c1 != c2, return false
	beq $t0, $zero, are_equal	# if reached the end of both strings, return true
	addi $a0, $a0, 1					# else, increase the pointers to both strings
	addi $a1, $a1, 1					#	increase the pointers to both strings
	j str_compare_loop				# and check next char

	not_equal:
	li $v0, 0
	j sc_pop_ret
	are_equal:
	li $v0, 1

	sc_pop_ret:
	# pop from stack
	lw $a0, 0 ($sp)			# used as a pointer to string1
	lw $a1, 4 ($sp)			# used as a pointer to string2
	lw $t0, 8 ($sp)			# used to store a temp char from string1
	lw $t1, 12($sp)			# used to store a temp char from string2
	addi $sp, $sp, 16

	jr $ra

# FUNCAO QUE LE UMA STRING, CHECA SE NELA TEM A DEClARACAO DE UMA LABEL, E RETORNA UMA STRING COM O NOME DA LABEL
get_label_dec:
# $a0: ponteiro para a string (linha)
# $v0: 1 se achou uma label, 0 se não achou
# $v1: ponteiro para o próximo char depois do ':' na string recebida em $a1, se $v0 = 1
# OBS: string que representa a label é guardada em um buffer de local fixo na memória, na label "label_dec_str"

	# push to stack
	subi $sp, $sp, 24
	sw $a0,  0($sp)		# used as a pointer to string to be read
	sw $t0,  4($sp)		# used as a pointer to label being constructed
	sw $t1,  8($sp)		# used as a temp for char being read
	sw $t2, 12($sp)		# used as a flag for set less than
	sw $t3, 16($sp)		# used to store immediate for comparison
	sw $t4, 20($sp)		# used to store immediate for comparison

	# construir possivel label
	la $t0, label_dec_str		# set pointer to first char in write buffer

	gld_loop:
	lbu $t1, 0($a0)					# read char from line
	
	# if reached '\0', return false
	beq $t1, $zero, string_ended

	# if char is ':', end label
	beq $t1, ':', end_label
	
	# if char is valid (a-zA-Z0-9_%$) write to label buffer
		# valid symbols
	beq $t1, '_', is_valid
	beq $t1, '$', is_valid
	beq $t1, '%', is_valid
	
		# if 0-9
	li $t3, '0'
	li $t4, '9'
	slt $t2, $t1, $t3		# if char is less than '0'
	bne $t2, $zero, not_numeric
	slt $t2, $t4, $t1		# if '9' is less than char
	bne	$t2, $zero, not_numeric
	j is_valid					# if got here, is a number (and therefore valid)
	not_numeric:

		# if A-Z	
	li $t3, 'A'
	li $t4, 'Z'
	slt $t2, $t1, $t3		# if char is less than 'A'
	bne $t2, $zero, not_upcase
	slt $t2, $t4, $t1		# if 'Z' is less than char
	bne	$t2, $zero, not_upcase
	j is_valid					# if got here, is a number (and therefore valid)
	not_upcase:

		# if a-z	
	li $t3, 'a'
	li $t4, 'z'
	slt $t2, $t1, $t3		# if char is less than 'a'
	bne $t2, $zero, not_downcase
	slt $t2, $t4, $t1		# if 'z' is less than char
	bne	$t2, $zero, not_downcase
	j is_valid					# if got here, is a number (and therefore valid)
	not_downcase:

	j isnt_valid			# if got here, isnt a valid char

	# if is valid char
	is_valid:
	sb $t1, 0($t0)		# write char to buffer
	addi $t0, $t0, 1	# increase write buffer pointer
	addi $a0, $a0, 1	# increase input string pointer
	j gld_loop				# read next char

	# else (is invalid char) reset label (reset write pointer & increase read pointer)
	isnt_valid:
	la $t0, label_dec_str	# reset write buffer
	addi $a0, $a0, 1
	j gld_loop						# read next char

	# reached end of string ('\0') without finding a label
	string_ended:
	li $v0, 0							# return false
	j gld_pop_and_return	# pop & return

	# end label and return
	end_label:
	sb $zero, 0($t0)			# add a \0 to next char in label write buffer
	li $v0, 1
	addi $v1, $a0, 1			# return address of next char in string after label
	# move $v1, $a0					# return address of next char in string after label BUG IS HERE< GONNA CHANGE FROM MOVE TO ADD +1. BUG IS THAT ITS STARTING TO READ FROM ':'

	gld_pop_and_return:
	# pop from stack
	lw $a0,  0($sp)		# used as a pointer to string to be read
	lw $t0,  4($sp)		# used as a pointer to label being constructed
	lw $t1,  8($sp)		# used as a temp for char being read
	lw $t2, 12($sp)		# used as a flag for set less than
	lw $t3, 16($sp)		# used to store immediate for comparison
	lw $t4, 20($sp)		# used to store immediate for comparison
	addi $sp, $sp, 24

	jr $ra	# return

# FUNCAO QUE INSERE UMA STRING (QUE REPRESENTA UMA LABEL) E O ENDEREÇO DA LABEL EM UMA LISTA
insert_label:
# $a0: número que representa o endereço da próxima instrução após a label
# $a1: ponteiro para a string que representa a label
# $v0: address of new element
# OBS: formato do elemento da lista eh:
# 4 bytes: pointer to next list element (0 if last one)
# 4 bytes: the label's corresponding value
# up to '\0': the string representing the label

	# push to stack
	subi $sp, $sp, 32
	sw $t0,  0($sp)		# used for a counter for how much space should be alocated for new list element
	sw $t1,  4($sp)		# used to store '\0' for comparison
	sw $t2,  8($sp)		# used for comparison & as a pointer
	sw $t3, 12($sp)		# used to store $a0, since $a0 is used for syscalls
	sw $t4, 16($sp)		# used to store $a1 & as a pointer
	sw $a0, 20($sp)		# used for syscall
	sw $a1, 24($sp)		# used as a pointer to string

	move $t3, $a0				# move $a0 to $t3, because we need $a0 for the syscall
	move $t4, $a1				# mover $a1 to $t4, because we need to save it for later

	# count number of byter to allocate in heap
	li $t0, 8							# needs to allocate 1 word for label-address + 1 word for pointer to next list element
	li $t1, '\0' 					# immediate used to compare
	il_loop:
	lbu $t2, 0($a1)				# get char from label
	addi $t0, $t0, 1			# increase counter for number of chars to allocate
	addi $a1, $a1, 1			# increase label pointer (look at next character)
	bne $t2, $t1, il_loop	# while not '\0', keep looking and increasing counter
	# now $t0 contains the ammount of bytes we need to allocate

	# allocate memory
	move $a0, $t0
	li $v0, 9
	syscall

	# create list element
	sw $zero, 0($v0)	# address to next list element (null)
	sw $t3, 4($v0)		# label-address (endereço da intrução após a label no programa sendo compilado)
	
	# copy the string into list element
	# OBS: $t4 is pointer to first char
	# OBS: $a1 is pointer to after last char
	# OBS: $t2 is pointer to first char of list element
	addi $t2, $v0, 8	# set list ele pointer
	il_copy_str:
	lbu $t0, 0($t4)		# get char
	sb $t0, 0($t2)		# write char
	addi $t4, $t4, 1	# increase label str pointer
	addi $t2, $t2, 1	# increase list ele pointer
	bne $t4, $a1, il_copy_str	# while not at the end

	# if list is empty, point first to new label
	lw $t0, label_list						# get first element of list
	bne $t0, $zero, il_not_first	# if first is not null, skip this step
	sw $v0, label_list						# set first element as current one
	j il_update_last

	# if list isnt empty, make previous last element point to current last element
	il_not_first:
	lw $t0, label_list_end	# get last element
	sw $v0, 0($t0)					# first word is pointer to next element. make it point to element currently being created

	# point last element to new label
	il_update_last:
	la $t0, label_list_end
	sw $v0, 0($t0)

	# pop from stack
	lw $t0,  0($sp)		# used for a counter for how much space should be alocated for new list element
	lw $t1,  4($sp)		# used to store '\0' for comparison
	lw $t2,  8($sp)		# used for comparison & as a pointer
	lw $t3, 12($sp)		# used to store $a0, since $a0 is used for syscalls
	lw $t4, 16($sp)		# used to store $a1 & as a pointer
	lw $a0, 20($sp)		# used for syscall
	lw $a1, 24($sp)		# used as a pointer to string
	addi $sp, $sp, 32

	jr $ra	#return

# FUNCAO QUE LE UM ARQUIVO LINHA A LINHA E EXECUTA A FUNCAO DADA EM CADA LINHA
read_file_lines:
# $a0: nome do arquivo
# $a1: funcao a ser executada ($a0: linha da string, $a1: accumulate value) => accumulate value for next iteration
# $a2: initial value for reduce
# returns: void

	# push registers to the stack
	subi $sp, $sp, 52
	sw $a0,  0($sp)				# used for function calls
	sw $a1,  4($sp)				# used for function calls
	sw $a2,  8($sp)				# used for function calls
	sw $t0, 12($sp)				# used for file buffer pointer
	sw $t1, 16($sp)				# used for pointer to end of file buffer
	sw $t2, 20($sp)				# used read/write bytes from file buffer to string buffer
	sw $t3, 24($sp)				# used to store chars for comparison and insertion
	sw $t4, 28($sp)				# used to store end of buffer flag
	sw $t5, 32($sp)				# used to store EOF flag
	sw $t6, 36($sp)				# used to store the accumulate value of the given function
	sw $s0, 40($sp)				# used to store file descriptor
	sw $s1, 44($sp)				# used for line buffer pointer
	sw $ra, 48($sp)				# used for function calls
	
	move $t6, $a2					# store initial value
	

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
	
	###### CALL FUNCTION GIVEN, USING LINE BUFFER AS ARGUMENT 0, AND THE PREVIOUS RETURN AS ARGUMENT 1
	lw $t3, 4($sp)						# get function address
	la $a0, line_buffer				# set up line buffer as argument
	move $a1, $t6							# reduce argument previous accumulate or initial value
	la $ra, return_from_call	# set up return address
	jr $t3										# call function
	return_from_call:					# return
	move $t6, $v0							# save accumulate for next iteration
	
	###### ADD REST OF BUFFER TO NEXT LINE & RESET LINE POINTER
	# $t0: buffer pointer
	# $s1: line buffer pointer
	addi $t0, $t0, 1 						# current $t0 is '\n', move to next one
	la $s1, line_buffer					# reset line pointer to start of buffer
	write_buffer_to_line_loop:
	beq $t0, $t1, finished_with_buffer	# if finished writing from buffer, leave loop
	lbu $t3, 0($t0)							# get char from buffer
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

	# load return value
	lw $v0, 44($sp)

	# pop registers from the stack
	lw $a0,  0($sp)				# used for function calls
	lw $a1,  4($sp)				# used for function calls
	lw $a2,  8($sp)				# used for function calls
	lw $t0, 12($sp)				# used for file buffer pointer
	lw $t1, 16($sp)				# used for pointer to end of file buffer
	lw $t2, 20($sp)				# used read/write bytes from file buffer to string buffer
	lw $t3, 24($sp)				# used to store chars for comparison and insertion
	lw $t4, 28($sp)				# used to store end of buffer flag
	lw $t5, 32($sp)				# used to store EOF flag
	lw $t6, 36($sp)				# used to store the accumulate value of the given function
	lw $s0, 40($sp)				# used to store file descriptor
	lw $s1, 44($sp)				# used for line buffer pointer
	lw $ra, 48($sp)				# used for function calls
	addi $sp, $sp, 52
	
	jr $ra
	# return

# END OF FUNCTION

# read file code from https://stackoverflow.com/questions/37469323/assembly-mips-read-text-from-file-and-buffer/37505359#37505359
