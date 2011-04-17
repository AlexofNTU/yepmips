.text
main:
move $fp,$sp
addi $sp,$sp,0
L6:
addi $a0,$zero,0
sw $fp,0($sp)
addi $a0,$zero,6
jal _nfactor
addi $fp,$sp,0
move $a0,$v0
sw $fp,0($sp)
jal _printi
addi $fp,$sp,0
j L5
L5:
move $sp,$fp
j _exit
_nfactor:
move $fp,$sp
addi $sp,$sp,-16
L8:
sw $ra,-12($fp)
sw $s7,-8($fp)
move $s7,$a0
beq $s7,0,L0
L1:
lw $t1,0($fp)
sw $t1,0($sp)
subi $a0,$s7,1
jal _nfactor
addi $fp,$sp,16
mul $v0,$s7,$v0
L2:
lw $s7,-8($fp)
lw $ra,-12($fp)
j L7
L0:
addi $v0,$zero,1
j L2
L7:
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