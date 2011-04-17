.text
main:
move $fp,$sp
addi $sp,$sp,0
L11:
addi $a0,$zero,0
sw $fp,0($sp)
addi $a0,$zero,9
jal _odd
addi $fp,$sp,0
move $a0,$v0
sw $fp,0($sp)
jal _printi
addi $fp,$sp,0
j L10
L10:
move $sp,$fp
j _exit
_odd:
move $fp,$sp
addi $sp,$sp,-12
L13:
sw $ra,-8($fp)
addi $t1,$zero,1
beq $a0,0,L5
L6:
addi $t1,$zero,0
L5:
bne $t1,0,L7
L8:
lw $t1,0($fp)
sw $t1,0($sp)
subi $a0,$a0,1
jal _even
addi $fp,$sp,12
L9:
lw $ra,-8($fp)
j L12
L7:
addi $v0,$zero,0
j L9
L12:
move $sp,$fp
jr $ra
_even:
move $fp,$sp
addi $sp,$sp,-12
L15:
sw $ra,-8($fp)
addi $t1,$zero,1
beq $a0,0,L0
L1:
addi $t1,$zero,0
L0:
bne $t1,0,L2
L3:
lw $t1,0($fp)
sw $t1,0($sp)
subi $a0,$a0,1
jal _odd
addi $fp,$sp,12
L4:
lw $ra,-8($fp)
j L14
L2:
addi $v0,$zero,1
j L4
L14:
move $sp,$fp
jr $ra
_initArray:
move $fp,$sp
sll $a0,$a0,2
sw $ra,0($fp)
jal _malloc
lw $ra,0($fp)
addi $a2,$zero,0
move $a3,$v0
Loop:
bge $a2,$a0,_over
sw $a1,0($a3)
addi $a2,$a2,4
addi $a3,$a3,4
j Loop
_over:
move $sp,$fp
jr $ra