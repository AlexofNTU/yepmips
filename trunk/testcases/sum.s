.text
main:
	move $fp, $sp
	addi $sp, $sp, -12
	sw $ra, -4($fp)
	li $a0, 100
	sw $fp, 0($sp)
	jal P1_sum
	addi $fp, $sp, 12
	move $a0, $v0
	jal _printi
	addi $fp, $sp, 12
	lw $ra, -4($fp)
	move $sp, $fp
	halt
.text
P1_sum:
	move $fp, $sp
	addi $sp, $sp, -20
	sw $a0, -8($fp)
	sw $ra, -4($fp)
	li $at, 1
	beq $a0, $at, L4
	lw $v1, 0($fp)
	lw $v0, -8($fp)
	addi $a0, $v0, -1
	sw $v1, 0($sp)
	jal P1_sum
	addi $fp, $sp, 20
	lw $v1, -8($fp)
	add $v0, $v1, $v0
L3:
	lw $ra, -4($fp)
	j L8
L4:
	li $v0, 1
	j L3
L8:
	move $sp, $fp
	jr $0, $ra, $0

.text
_initArray:
	sll $a0, $a0, 2
	move $v0, $gp
	add $gp, $gp, $a0
	move $v1, $v0
	add $a0, $a0, $v0
	_initArray_0:
	sw $a1, 0($v1)
	addi $v1, $v1, 4
	bne $v1, $a0, _initArray_0
	jr $0, $ra, $0

_malloc:
	move $v0, $gp
	add $gp, $gp, $a0
	jr $0, $ra, $0

_printi:
	li $v0, 1
	syscall
	jr $0, $ra, $0

_print:
	li $v0, 4
	syscall
	jr $0, $ra, $0
