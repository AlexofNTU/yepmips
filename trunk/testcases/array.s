.text
main:
	move $fp, $sp
	addi $sp, $sp, -36
	sw $ra, -16($fp)
	sw $s7, -12($fp)
	sw $s6, -8($fp)
	sw $s5, -4($fp)
	li $a0, 100
	li $a1, 19
	jal _initArray
	addi $fp, $sp, 36
	move $s6, $v0
	li $v1, 0
	li $t0, 99
	ble $v1, $t0, L6
L4:
	li $s5, 0
	li $s7, 99
	ble $s5, $s7, L7
L5:
	lw $s5, -4($fp)
	lw $s6, -8($fp)
	lw $s7, -12($fp)
	lw $ra, -16($fp)
	j L8
L6:
	sll $a0, $v1, 2
	add $a0, $s6, $a0
	sw $v1, 0($a0)
	addi $v1, $v1, 1
	ble $v1, $t0, L6
	j L4
L7:
	sll $v0, $s5, 2
	add $v0, $s6, $v0
	lw $a0, 0($v0)
	jal _printi
	addi $fp, $sp, 36
	addi $v1, $s5, 1
	move $s5, $v1
	ble $v1, $s7, L7
	j L5
L8:
	move $sp, $fp
	halt

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
