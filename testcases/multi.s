.text
main:
	move $fp, $sp
	addi $sp, $sp, -52
	sw $ra, -24($fp)
	sw $s7, -20($fp)
	sw $s6, -16($fp)
	sw $s5, -12($fp)
	sw $s4, -8($fp)
	sw $s3, -4($fp)
	li $a0, 12
	jal _malloc
	addi $fp, $sp, 52
	move $s3, $v0
	li $s4, 0
	li $s6, 2
	ble $s4, $s6, L11
L10:
	move $s5, $s3
	lw $v0, 8($s3)
	lw $a0, 12($v0)
	jal _printi
	addi $fp, $sp, 52
	li $v1, 0
	li $a0, 2
	ble $v1, $a0, L16
L12:
	li $s4, 0
	li $s7, 2
	ble $s4, $s7, L18
L14:
	lw $v0, 8($s5)
	sw $zero, 12($v0)
	lw $v0, 8($s5)
	lw $a0, 12($v0)
	jal _printi
	addi $fp, $sp, 52
	lw $s3, -4($fp)
	lw $s4, -8($fp)
	lw $s5, -12($fp)
	lw $s6, -16($fp)
	lw $s7, -20($fp)
	lw $ra, -24($fp)
	j L20
L11:
	sll $v0, $s4, 2
	add $s5, $s3, $v0
	li $a0, 4
	li $a1, 888
	jal _initArray
	addi $fp, $sp, 52
	sw $v0, 0($s5)
	addi $v0, $s4, 1
	move $s4, $v0
	ble $v0, $s6, L11
	j L10
L16:
	li $v0, 0
	li $t0, 3
	ble $v0, $t0, L17
L13:
	addi $v1, $v1, 1
	ble $v1, $a0, L16
	j L12
L17:
	sll $t1, $v1, 2
	add $t1, $s5, $t1
	lw $t2, 0($t1)
	sll $t1, $v0, 2
	add $t2, $t2, $t1
	add $t1, $v1, $v1
	add $t1, $t1, $v1
	add $t1, $t1, $v1
	add $t1, $t1, $v0
	sw $t1, 0($t2)
	addi $v0, $v0, 1
	ble $v0, $t0, L17
	j L13
L18:
	li $s3, 0
	li $s6, 3
	ble $s3, $s6, L19
L15:
	addi $v0, $s4, 1
	move $s4, $v0
	ble $v0, $s7, L18
	j L14
L19:
	sll $v0, $s4, 2
	add $v0, $s5, $v0
	lw $v1, 0($v0)
	sll $v0, $s3, 2
	add $v0, $v1, $v0
	lw $a0, 0($v0)
	jal _printi
	addi $fp, $sp, 52
	addi $v0, $s3, 1
	move $s3, $v0
	ble $v0, $s6, L19
	j L15
L20:
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
