.text
main:
move $fp,$sp
addi $sp,$sp,0
L5:
addi $t1,$zero,0
addi $t0,$zero,0
addi $a0,$zero,0
blt $t1,5,L3
L0:
sw $fp,0($sp)
jal _printi
addi $fp,$sp,0
j L4
L3:
blt $t0,10,L2
L1:
addi $t0,$zero,0
addi $t1,$t1,1
blt $t1,5,L3
L6:
j L0
L2:
addi $a0,$a0,1
addi $t0,$t0,1
blt $t0,10,L2
L7:
j L1
L4:
move $sp,$fp
j _exit
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