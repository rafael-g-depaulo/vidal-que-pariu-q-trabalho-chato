.data
# USED BY "transcribe_data"
dot_data:							.space 	80		# array que vai guardar o .data do programa sendo compilado
dot_data_used:				.word 	0			# quantidada de bytes ja escritos no dot_data
# USED TO TEST "transcribe_data"
data_test:						.asciiz	"     .word    asdrr: 6,0,15 \n\n LABEL_TEST: .word 35 "

# USED BY "insert_data_text"
data_start:						.word		0			# ponteiro para o primeiro elemento da lista de linhas do .data
data_end:							.word		0			# ponteiro para o ultimo elemento da lista de linhas do .data
text_start:						.word		0			# ponteiro para o primeiro elemento da lista de linhas do .text
text_end:							.word		0			# ponteiro para o ultimo elemento da lista de linhas do .text
data_str:							.ascii 	"data"
text_str:							.ascii 	"text"
# USED TO TEST "insert_data_text"
line1:								.asciiz ".data test1: .word 2, 2, 2, 2"
line2:								.asciiz "test2: .word 2, 2, 2, 2"
line3:								.asciiz ".text"
line4:								.asciiz "  \t li $t2, 0x234"

# USED BY "get_label_use"
label_use_str:				.space 	40

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
	
	# # separate lines into .data & .text lists
	# move $a0, $v0	# file name
	# la $a1, insert_data_text	# function to separate lines
	# jal read_file_lines

	la $a0, data_test
	jal transcribe_data

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

	# # insert data text test
	# la $a0, line1
	# li $a1, 0
	# jal insert_data_text

	# la $a0, line2
	# move $a1, $v0
	# jal insert_data_text
	# la $a0, line3
	# move $a1, $v0
	# jal insert_data_text
	# la $a0, line4
	# move $a1, $v0
	# jal insert_data_text

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

# FUNCAO QUE PERCORRE UMA LINHA INTEIRA DO .data, CONTA DADOS A SEREM INICIALIZADOS NA MEMÓRIA, E DECLARA E INICIALIZA LABELS DO .data
##### UNTESTED #################
##### UNTESTED #################
##### UNTESTED #################
##### UNTESTED #################
transcribe_data:
# $a0: ponteiro para string (linha)
# $v0: quantidade de words achadas
	
	# push to stack
	subi $sp, $sp, 40
	sw $a0,  0($sp) # $a0: used to traverse line, function calls
	sw $a1,  4($sp)	# $a1: function calls
	sw $t0,  8($sp)	# $t0: aux to hold char, pointer to string of name of label found
	sw $t1, 12($sp)	# $t1: flag for comparison
	sw $t2, 16($sp)	# $t2: holds char used for comparison
	sw $t3, 20($sp)	# $t3: holds char used for comparison
	sw $s0, 24($sp)	# $s0: hols pointer to next free spot in .data array
	sw $s1, 28($sp)	# $s1: holds number of words written in .data array already
	sw $s2, 32($sp)	# $s2: holds address of next word in the compiled document
	sw $ra, 36($sp)	# $ra: function calls

	# load $s0, $s10 and $s2
	lw $s1, dot_data_used				# number of bytes already occupied
	la $s0, dot_data						# pointer to start of .data
	add $s0, $s0, $s1						# pointer to next available spot in .data
	lui $s2, 0x1001							# load start of .data
	add $s2, $s2, $s1						# add ammount of bytes already occupied

	# percorrer a string ate achar nao-whitespace (se achar '\0' para)
	td_getchar:
	lbu $t0, 0($a0) 					# get char
	addi $a0, $a0, 1					# increase pointer
	beq $t0, ' ', td_getchar	# while char == ' '
	beq $t0, ',', td_getchar	# while char == ','
	beq $t0, '\t', td_getchar	# while char == '\t'
	beq $t0, '\n', td_getchar	# while char == '\n'
	beq $t0, $zero, td_found_end_of_line

	# now $t0 has a char thats not a whitespace

	# se '.', eh .word
	bne $t0, '.', td_not_dot
	addi $a0, $a0, 4	# point to after ".word"
	j td_getchar			# get next char
	td_not_dot:

	# checa se e numero ('0'-'9')
	li $t2, '0'
	li $t3, '9'
	slt $t1, $t0, $t2		# if digit is less than '0'
	bne $t1, $zero, td_not_num
	slt $t1, $t3, $t0		# if '9' is less than digit
	bne	$t1, $zero, td_not_num

	# se for, insira o numero na array do dot_data e aumente o size
	subi $a0, $a0, 1	# point $a0 to first digit of nuber to be read
	jal get_imm
	move $a0, $v1			# get pointer to char right after number read
	sw $v0, 0($s0)		# write word to memory
	addi $s0, $s0, 4	# increase .data pointer
	addi $s1, $s1, 4	# increase counter of how many bytes have been read
	addi $s2, $s2, 4	# increase pointer for .data of file being read

	j td_getchar			# get next char
	td_not_num:
	# if got here, it's a label declaration

	# get label string
	subi $a0, $a0, 1	# point $a0 to first char of label string
	jal get_label_dec	# get label
	move $t0, $v1			# save line pointer of char after label dec

	# insert new label
	move $a0, $s2					# load label address
	la $a1, label_dec_str	# load label string (got from calling get_label_dec)
	jal insert_label			# add new label

	move $a0, $t0			# load pointer of right after label dec
	j td_getchar			# get next char

	# found end of line (return)
	td_found_end_of_line:
	# save in memory how many words have been written in .data
	sw $s1, dot_data_used

	# pop
	lw $a0,  0($sp) # $a0: used to traverse line, function calls
	lw $a1,  4($sp)	# $a1: function calls
	lw $t0,  8($sp)	# $t0: aux to hold char, pointer to string of name of label found
	lw $t1, 12($sp)	# $t1: flag for comparison
	lw $t2, 16($sp)	# $t2: holds char used for comparison
	lw $t3, 20($sp)	# $t3: holds char used for comparison
	lw $s0, 24($sp)	# $s0: hols pointer to next free spot in .data array
	lw $s1, 28($sp)	# $s1: holds number of words written in .data array already
	lw $s2, 32($sp)	# $s2: holds address of next word in the compiled document
	lw $ra, 36($sp)	# $ra: function calls
	addi $sp, $sp, 40

	jr $ra	# return

# FUNCAO QUE LE UMA STRING, CHECA SE NELA TEM UM IMEDIATO SENDO USADO, E RETORNA O VALOR DA LABEL,
#   E UM PONTEIRO PARA LOGO APÓS O USO DELE
get_imm:
# $a0: ponteiro para a string (linha)
# $v0: valor do imediato
# $v1: ponteiro para o próximo char depois do último caracter da label na string recebida em $a1

	# push to stack
	subi $sp, $sp, 28
	sw $a0,  0($sp)			# used as a pointer to line string
	sw $t0,  4($sp)			# used to check if number is hex
	sw $t1,  8($sp)			# used to store the digit read from $a0, and to check if number is hex
	sw $t2, 12($sp)			# used to store constants for comparison, and to check if number is hex
	sw $t3, 16($sp)			# used to store constants for comparison
	sw $t4, 20($sp)			# used to store constants for comparison
	sw $t7, 24($sp)			# used for negative number flag

	# navigate the line until a non ',', non whitespace char appears
	gi_loop:
	lbu $t1, 0($a0)						# read char
	addi $a0, $a0, 1					# increase pointer
	beq $t1, ',' , gi_loop		# if whitespace, keep looking
	beq $t1, ' ' , gi_loop		# if whitespace, keep looking
	beq $t1, '\t', gi_loop		# if whitespace, keep looking
	beq $t1, '\n', gi_loop		# if whitespace, keep looking
	
	bne $t1, '-', gi_not_neg	# if it's negative, set up a flag
	li $t7, 1									# flag that makes the number negative
	addi $a0, $a0, 1					# increase pointer
	
	gi_not_neg:
	subi $a0, $a0, 1					# pointer is pointing to digit after first. fix that by subtracting 1
	
	# now check if its a hex or dec number
	lbu $t0, 0($a0)							# 1st character
	lbu $t2, 1($a0)							# 2nd character
	bne $t0, '0', gi_dec				# if doesnt start with '0x'...
	bne $t2, 'x', gi_dec				# ... its a decimal number
	# else, it's hex
	addi $a0, $a0, 2						# go for after the '0x' to start reading
	
	# HEXADECIMAL
	li $v0, 0									# start

	gi_hex_loop:
	lbu $t1, 0($a0)						# get digit

	# check if digit is 'a'-'f'
	li $t3, 'a'
	li $t4, 'f'
	slt $t2, $t1, $t3			# if digit is less than 'a'
	bne $t2, $zero, gi_hex_not_lowcase
	slt $t2, $t4, $t1			# if '9' is less than digit
	bne	$t2, $zero, gi_hex_not_lowcase
	# se chegou aqui, esta em 'a'-'f'
	subi $t1, $t1, 'a'		# transforma t de 'a'-'f' pra 0-5
	addi $t1, $t1, 10			# transforma t de 0-5 pra 10-15
	j gi_hex_valid_digit	# adicione o digito ao numero
	gi_hex_not_lowcase:

	# check if digit is 'A'-'F'
	li $t3, 'A'
	li $t4, 'F'
	slt $t2, $t1, $t3			# if digit is less than 'A'
	bne $t2, $zero, gi_hex_not_upcase
	slt $t2, $t4, $t1			# if '9' is less than digit
	bne	$t2, $zero, gi_hex_not_upcase
	# se chegou aqui, esta em 'a'-'f'
	subi $t1, $t1, 'A'		# transforma t de 'A'-'F' pra 0-5
	addi $t1, $t1, 10			# transforma t de 0-5 pra 10-15
	j gi_hex_valid_digit	# adicione o digito ao numero
	gi_hex_not_upcase:
	
	# check if digit is 0-9
	li $t3, '0'
	li $t4, '9'
	slt $t2, $t1, $t3		# if digit is less than '0'
	bne $t2, $zero, gi_hex_num_ended
	slt $t2, $t4, $t1		# if '9' is less than digit
	bne	$t2, $zero, gi_hex_num_ended
	# se chegou aqui, esta em '0'-'9'
	subi $t1, $t1, '0'	# transforma t de '0'-'9' pra 0-9

	gi_hex_valid_digit:
	# confirmed that $t1 hold a digit
	sll $v0, $v0, 4		# multiply number by 16
	add $v0, $v0, $t1		# add t1's value to $v0

	addi $a0, $a0, 1		# increase line pointer (to get next digit)
	j gi_hex_loop				# get next digit

	gi_hex_num_ended:
	move $v1, $a0				# load return pointer (points to right after number)
	beq $t7, $zero, gi_hex_not_neg	# if not negative, dont negate
	not $v0, $v0				# invert
	addi $v0, $v0, 1		# add 1
	gi_hex_not_neg:
	j gi_pop_and_return	# pop & return

	# DECIMAL
	gi_dec:
	li $v0, 0									# start 
	gi_dec_loop:
	lbu $t1, 0($a0)						# get digit

	# if char isnt valid, end number
	li $t3, '0'
	li $t4, '9'
	slt $t2, $t1, $t3		# if digit is less than '0'
	bne $t2, $zero, gi_dec_num_ended
	slt $t2, $t4, $t1		# if '9' is less than digit
	bne	$t2, $zero, gi_dec_num_ended
	
	# confirmed that $t1 hold a digit
	subi $t1, $t1, '0'	# conver t1 from char to int
	mul $v0, $v0, 10		# multiply number by 10
	add $v0, $v0, $t1		# add t1's value to $v0

	addi $a0, $a0, 1		# increase line pointer (to get next digit)
	j gi_dec_loop				# get next digit

	gi_dec_num_ended:
	move $v1, $a0				# load return pointer (points to right after number)
	beq $t7, $zero, gi_dec_not_neg	# if not negative, dont negate
	not $v0, $v0				# invert
	addi $v0, $v0, 1		# add 1
	gi_dec_not_neg:
	
	# pop from stack
	gi_pop_and_return:
	lw $a0,  0($sp)			# used as a pointer to line string
	lw $t0,  4($sp)			# used to check if number is hex
	lw $t1,  8($sp)			# used to store the digit read from $a0, and to check if number is hex
	lw $t2, 12($sp)			# used to store constants for comparison, and to check if number is hex
	lw $t3, 16($sp)			# used to store constants for comparison
	lw $t4, 20($sp)			# used to store constants for comparison
	lw $t7, 24($sp)			# used for negative number flag
	addi $sp, $sp, 28

	jr $ra	# return

# FUNCAO QUE LE UMA STRING, CHECA SE NELA TEM UMA LABEL SENDO USADA, E RETORNA O VALOR DA LABEL, E UM PONTEIRO PARA LOGO APÓS O USO DELA
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

# FUNCAO QUE DIVIDE AS LINHAS DE UM ARQUIVO ENTRE .data E .text
insert_data_text:
# $a0: ponteiro pra linha
# $a1: 1 -> inserir em .data, 2 -> inserir em .text, 0 -> nao inserir em nenhum dos dois
# $v0: 1 -> ja estava em ".data" e nao mudou, ou mudou para modo ".data"
#			 2 -> ja estava em ".text" e nao mudou, ou mudou para modo ".text"
#			 0 -> estava em 0, e nao achou ".data" ou ".text" na linha

	# push to stack
	subi $sp, $sp, 36
	sw $ra,  0($sp)		# used for function calls
	sw $a0,  4($sp)		# used for function calls
	sw $a1,  8($sp)		# used for function calls
	sw $t0, 12($sp)		# pointer to line string, pointer to start of list to be written to
	sw $t1, 16($sp)   # aux char read from line, pointer to end of list to be written to
	sw $t2, 20($sp)   # aux to construct .data/.text string for
	sw $t3, 24($sp)   # aux to read char from string
	sw $t4, 28($sp)		# used to store copy to $a0
	sw $t5, 32($sp)		# used to store return value
	
	move $t5, $a1 		# initially set return to same as $a1
	
	# search through line to see if it's changing from .data/.text or vice-versa
	# look for '.'
	move $t0, $a0			# go to start of line
	idt_look_for_period_loop:
	lbu $t1, 0($t0)					# get char
	addi $t0, $t0, 1				# increase pointer
	beq $t1, '\0', idt_not_changing_modes
	bne $t1, '.', idt_look_for_period_loop

	# check if ".data" or ".text"
	# get 4 characters after '.' (looking for either .data or .text)
	lbu $t2, 3($t0)					# load 4th char of line
	move $t1, $t2						# add 4th char
	sll $t1, $t1, 8					# shift to the side
	lbu $t2, 2($t0)					# load 3rd char of line
	or  $t1, $t1, $t2				# add 3rd char
	sll $t1, $t1, 8					# shift to the side
	lbu $t2, 1($t0)					# load 2nd char of line
	or  $t1, $t1, $t2				# add 2nd char
	sll $t1, $t1, 8					# shift to the side
	lbu $t2, 0($t0)					# load 1st char of line
	or  $t1, $t1, $t2				# add 1st char
	# $t1 holds the 4 chars after '.' on the line string

	# check if ".data"
	lw $t2, data_str
	bne $t1, $t2, idt_not_data
	# got here -> is .data
	addi $a0, $t0, 4		# set up line pointer to right after ".data"
	li $t5, 1				 		# load $v0
	j idt_call_itself_again
	idt_not_data:

	# check if ".text"
	lw $t2, text_str
	bne $t1, $t2, idt_not_changing_modes
	# got here -> is .text
	addi $a0, $t0, 4		# set up line pointer to right after ".text"
	li $t5, 2				 		# load $v0
	j idt_call_itself_again

	idt_not_changing_modes:	# didn't find a ".data" or ".text"

	# decide (based on $a1) which list to add element to
	
	# check if in .data
	li $t0, 1
	bne $a1, $t0, idt_insert_not_data
	# if got here, insert into data
	la $t0, data_start	# load start of list
	la $t1, data_end		# load end of list
	j idt_create_element
	idt_insert_not_data:

	# check if in .text
	li $t0, 2
	bne $a1, $t0, idt_insert_not_text
	# if got here, insert into data
	la $t0, text_start	# load start of list
	la $t1, text_end		# load end of list
	j idt_create_element
	idt_insert_not_text:
	# if got here, should just return.
	# just go pop and return
	j idt_pop_and_return
	
	# create list element
	idt_create_element:

	# get line length to alocate memory for it
	move $t4, $a0									# save copy of line pointer
	li $t2, 0											# counter = 0
	idt_line_size:
	lbu $t3, 0($t4)								# getchar
	addi $t2, $t2, 1							# counter++
	addi $t4, $t4, 1							# pointer++
	bne $t3, $zero, idt_line_size	# while char != '\0'
	# from here, $t2 has the size of the line string

	# alocate memory for the new list element
	move $t3, $a0 		# save $a0
	addi $a0, $t2, 4	# 4 more bytes for the pointer to the next list element
	li $v0, 9
	syscall
	move $a0, $t3 		# reload $a0
	# set .next to null
	sw $zero, 0($v0)

	# if list.fist = null, set this as first
	lw $t2, 0($t0)
	bne $t2, $zero, idt_list_not_empty
	sw $v0, 0($t0)
	j ist_set_last_element

	# if list.last != null, set list.last.next to this
	idt_list_not_empty:
	lw $t2, 0($t1)
	sw $v0, 0($t2)
	
	# set list.last to this
	ist_set_last_element:
	sw $v0, 0($t1)

	# copy string from $a0 into list element
	# $v0: pointer to list element
	# $a0: line pointer
	# $t0: pointer to list element.line (the section where the string can be copied to)
	# $t1: aux
	addi $t0, $v0, 4		# get list element.line pointer
	idt_copy_str_loop:
	lbu $t1, 0($a0)			# get char
	sb $t1, 0($t0)			# copy char to list element
	addi $a0, $a0, 1		# increase line pointer
	addi $t0, $t0, 1		# increase list element line pointer
	bne $t1, $zero, idt_copy_str_loop	# while char != '\0'

	j idt_pop_and_return
	idt_call_itself_again:
	# if got here, found a .data and $v0 was updater accordingly.
	# insert rest of line in the apropriate list
	# $a0 is already pointing to after .data/.text in line
	move $a1, $t5	# load which line to insert it into
	jal insert_data_text	# call itself
	# now pop and return

	idt_pop_and_return:
	move $v0, $t5			# set return value
	
	# pop from stack
	lw $ra,  0($sp)		# used for function calls
	lw $a0,  4($sp)		# used for function calls
	lw $a1,  8($sp)		# used for function calls
	lw $t0, 12($sp)		# pointer to line string, pointer to start of list to be written to
	lw $t1, 16($sp)   # aux char read from line, pointer to end of list to be written to
	lw $t2, 20($sp)   # aux to construct .data/.text string for
	lw $t3, 24($sp)   # aux to read char from string
	lw $t4, 28($sp)		# used to store copy to $a0
	lw $t5, 32($sp)		# used to store return value
	addi $sp, $sp, 36
	
	jr $ra # return

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

######## FUNCAO PARA ACHAR O NUMERO DE UM REGISTRADOR
# t0 = endereco de algum ponto da string antes do reg
# t1 = em primeira instancia, o primeiro digito do reg. apos verificar de qual 'familia' o reg e, 
#	t1 vai ser o comparador do segundo digito (economia de reg
# t2 = na primeira parte, sera o comparador do primeiro digito do reg
# t3 = vai guardar o segundo digito do reg
# v0 = retorno com o valor (numero) do reg
# v1 = retorno com o endereco na string apos o reg
#

get_reg:
	addi $sp, $sp, -16   	####
	sw $t0, 0($sp)		# preparando a stack
	sw $t1, 4($sp)		#
	sw $t2, 8($sp)		#
	sw $t3, 12($sp)		####

# do funct
	addi $t2, $zero, '$'	# $t2 = '$', para comparar e checar se encontrou um reg
	
GRloop:
	lbu $t1, 0($t0)			#	ler char por char (byte por byte) | $t1 = um byte (char) da string
	addi $t0, $t0, 1		# próximo byte
	bne $t2, $t1, GRloop 		# enquanto eu nao encontrar um '$' eu continuo procurando
	
	lbu $t1, 0($t0)			#	ler char depois do '$' para checar qual reg usado
	addi $t0, $t0, 1		# próximo byte
	
	lbu $t3, 0($t0)			# 	para evitar repeticoes, ja guardo aqui o segundo
	addi $t0, $t0, 1		# digito do reg, e o endereco de retorno logo apos o reg (em t3).
	add $v1, $zero, $t0		# v1 ja tem o endereco de retorno apos o reg
	
	addi $t2, $zero, 'v'	####
	beq $t1, $t2, GRfamV	#
	addi $t2, $zero, 'a'	#
	beq $t1, $t2, GRfamA	#
	addi $t2, $zero, 't'	# 	checa se o reg e da familia 'n', e manda pra
	beq $t1, $t2, GRfamT	# outro teste checar qual dos reg dessa familia 'n'
	addi $t2, $zero, 's'	#
	beq $t1, $t2, GRfamS	#
	addi $t2, $zero, 'k'	#
	beq $t1, $t2, GRfamK	####
	
	addi $t2, $zero, 'r'	####
	beq $t1, $t2, GRfamR	#
	addi $t2, $zero, 'g'	#
	beq $t1, $t2, GRfamG	#
	addi $t2, $zero, 'f'	#	caso so tenha um reg na 
	beq $t1, $t2, GRfamF	# familia 'n', nao ha mais testes.
	addi $t2, $zero, 'z'	# so atribui o v0 e encerra a funcao.
	beq $t1, $t2, GRfamZ	####

# 	como a informacao em t1 nao e mais relevante, vou alterar seu
#	valor para encontrar qual dos membros da familia 'n' e o reg atual.

	GRfamR:
		addi $v0, $zero, 31
		j end_get_reg	
	GRfamG:
		addi $v0, $zero, 28
		j end_get_reg	
	GRfamF:
		addi $v0, $zero, 30
		j end_get_reg
	GRfamZ:
		addi $v1, $v1, 2	# o v1 guarda o endereco duas casas apos o '$', mas o zero e o unico reg com 4 casas. hence this
		addi $v0, $zero, 0
		j end_get_reg
	###### famV
	GRfamV:
		addi $t1, $zero, '0'	# t1 = 0, para testar se e o reg v0
		beq $t1, $t3, GRV0	# se for igual, o reg e v0, retorna valor 2 no v0 (retorno da func)
		addi $v0, $zero, 3	# se t3 nao for 0, so pode ser 1, entao e o reg v1. retorno da func sera 3
		j end_get_reg
	GRV0: 
		addi $v0, $zero, 2
		j end_get_reg
	###### end famV
	###### famA
	GRfamA:
		addi $t1, $zero, 't'
		beq $t1, $t3, GRAT	# checando se o t3 tem um 't' nele, se sim, e o reg at... e por ai vai
		addi $t1, $zero, '0'
		beq $t1, $t3, GRA0
		addi $t1, $zero, '1'
		beq $t1, $t3, GRA1
		addi $t1, $zero, '2'
		beq $t1, $t3, GRA2	# se passou de todos os testes, a unica possibilidade e o a3, valor 7
		addi $v0, $zero, 7
		j end_get_reg

		GRAT:
			addi $v0, $zero, 1
			j end_get_reg
		GRA0:
			addi $v0, $zero, 4
			j end_get_reg
		GRA1:
			addi $v0, $zero, 5
			j end_get_reg
		GRA2:
			addi $v0, $zero, 6
			j end_get_reg	
	###### end famA
	###### famT
	GRfamT:
		addi $t1, $zero, '0'	# checa qual da familia do 't' é o reg atual... e por ai vai
		beq $t1, $t3, GRT0
		addi $t1, $zero, '1'
		beq $t1, $t3, GRT1
		addi $t1, $zero, '2'
		beq $t1, $t3, GRT2
		addi $t1, $zero, '3'
		beq $t1, $t3, GRT3
		addi $t1, $zero, '4'
		beq $t1, $t3, GRT4
		addi $t1, $zero, '5'
		beq $t1, $t3, GRT5
		addi $t1, $zero, '6'
		beq $t1, $t3, GRT6
		addi $t1, $zero, '7'
		beq $t1, $t3, GRT7
		addi $t1, $zero, '8'	# se nao passar em nenhum caso até agora, a unica possibilidade e ser o t9
		beq $t1, $t3, GRT8
		addi $v0, $zero, 25
		j end_get_reg
		
		GRT0:
			addi $v0, $zero, 8
			j end_get_reg
		GRT1:
			addi $v0, $zero, 9
			j end_get_reg
		GRT2:
			addi $v0, $zero, 10
			j end_get_reg
		GRT3:
			addi $v0, $zero, 11
			j end_get_reg
		GRT4:
			addi $v0, $zero, 12
			j end_get_reg
		GRT5:
			addi $v0, $zero, 13
			j end_get_reg
		GRT6:
			addi $v0, $zero, 14
			j end_get_reg
		GRT7:
			addi $v0, $zero, 15
			j end_get_reg
		GRT8:
			addi $v0, $zero, 24
			j end_get_reg
	###### end famT
	###### famS
	GRfamS:
		addi $t1, $zero, 'p'
		beq $t1, $t3, GRSP
		addi $t1, $zero, '0'
		beq $t1, $t3, GRS0
		addi $t1, $zero, '1'
		beq $t1, $t3, GRS1
		addi $t1, $zero, '2'
		beq $t1, $t3, GRS2
		addi $t1, $zero, '3'
		beq $t1, $t3, GRS3
		addi $t1, $zero, '4'
		beq $t1, $t3, GRS4
		addi $t1, $zero, '5'
		beq $t1, $t3, GRS5
		addi $t1, $zero, '6'	# de novo, se falha em todos os casos ate agr, so sobra o s7 de possibilidade
		beq $t1, $t3, GRS6
		addi $v0, $zero, 23
		j end_get_reg
		
		GRSP:
			addi $v0, $zero, 29
			j end_get_reg
		GRS0:
			addi $v0, $zero, 16
			j end_get_reg		
		GRS1:
			addi $v0, $zero, 17
			j end_get_reg
		GRS2:
			addi $v0, $zero, 18
			j end_get_reg
		GRS3:
			addi $v0, $zero, 19
			j end_get_reg
		GRS4:
			addi $v0, $zero, 20
			j end_get_reg
		GRS5:
			addi $v0, $zero, 21
			j end_get_reg
		GRS6:
			addi $v0, $zero, 22
			j end_get_reg
	###### end famS
	###### famK
	GRfamK:
		addi $t1, $zero,'0' 
		beq $t1, $t3, GRK0		# se nao for k0, a unica possibilidade e k1
		addi $v0, $zero, 27
		j end_get_reg
		
		GRK0:
			addi $v0, $zero, 26
			j end_get_reg
	###### end famK
	
# done funct
	
end_get_reg:				# ao chegar aq, v0 = numero do reg, v1 = endereco da string logo apos o reg
	lw $t3, 12($sp)			####
	lw $t2, 8($sp)			#
	lw $t1, 4($sp)			# retornando a stack
	lw $t0, 0($sp)			#
	addi $sp, $sp, 16		####
	
	jr $ra
######## fim da funcao pra achar o numero do registrador

# read file code from https://stackoverflow.com/questions/37469323/assembly-mips-read-text-from-file-and-buffer/37505359#37505359
