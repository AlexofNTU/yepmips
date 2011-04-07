.text
main:
	move $fp, $sp
	addi $sp, $sp, -16
	sw $ra, -12($fp)
	addi $v0, $fp, -4
	sw $v0, -8($fp)
	li $a0, 3
	move $a1, $zero
	jal _initArray
	addi $fp, $sp, 16
	lw $v1, -8($fp)
	sw $v0, 0($v1)
	li $a0, 3
	sw $fp, 0($sp)
	jal P2_f
	addi $fp, $sp, 16
	lw $ra, -12($fp)
	move $sp, $fp
	halt
.text
P2_f:
	move $fp, $sp
	addi $sp, $sp, -44
	sw $a0, -12($fp)
	sw $ra, -20($fp)
	sw $s7, -16($fp)
	sw $s6, -8($fp)
	sw $s5, -4($fp)
	li $at, 0
	beq $a0, $at, L14
	li $s5, 0
	li $s7, 2
	ble $s5, $s7, L16
L13:
	lw $s5, -4($fp)
	lw $s6, -8($fp)
	lw $s7, -16($fp)
	lw $ra, -20($fp)
	j L22
L14:
	li $s5, 0
	li $s6, 2
	ble $s5, $s6, L11
L10:
	move $a0, $zero
	jal _printi
	addi $fp, $sp, 44
	j L13
L11:
	lw $v0, 0($fp)
	lw $v1, -4($v0)
	sll $v0, $s5, 2
	add $v0, $v1, $v0
	lw $a0, 0($v0)
	jal _printi
	addi $fp, $sp, 44
	addi $v0, $s5, 1
	move $s5, $v0
	ble $v0, $s6, L11
	j L10
L16:
	lw $v1, 0($fp)
	lw $a0, -4($v1)
	sll $v1, $s5, 2
	add $v1, $a0, $v1
	lw $v1, 0($v1)
	li $at, 0
	beq $v1, $at, L18
L17:
	addi $v1, $s5, 1
	move $s5, $v1
	ble $v1, $s7, L16
	j L13
L18:
	lw $t0, 0($fp)
	lw $v0, -4($t0)
	sll $s6, $s5, 2
	add $v1, $v0, $s6
	lw $v0, -12($fp)
	sw $v0, 0($v1)
	lw $v0, -12($fp)
	addi $a0, $v0, -1
	sw $t0, 0($sp)
	jal P2_f
	addi $fp, $sp, 44
	lw $v1, 0($fp)
	lw $v1, -4($v1)
	add $v1, $v1, $s6
	sw $zero, 0($v1)
	j L17
L22:
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
