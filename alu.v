module ALU(EALUC, EXA, EXB, EXALU);
input[3:0] 		EALUC;
input[31:0]		EXA, EXB;
output[31:0]	EXALU;
reg[31:0]		EXALU;

always @(EALUC,EXA,EXB)
begin
	//add
	if (EALUC == 4'b0010)
		EXALU = EXA + EXB;
	//sub
	if (EALUC == 4'b0110)
		EXALU = EXA - EXB;
	//and
	if (EALUC == 4'b0000)
		EXALU = EXA & EXB;
	//or
	if (EALUC == 4'b0001)
		EXALU = EXA | EXB;
	//less than
	if (EALUC == 4'b0111)//TODO is signed!
	begin
		EXALU = (EXA < EXB)? 1:0;
		if (EXA[31]==1 && EXB[31]==0) EXALU = 1;
		if (EXA[31]==0 && EXB[31]==1) EXALU = 0;
	end
	//xor
	if (EALUC == 4'b1100)
		EXALU =  EXA ^ EXB;
	//shift left
	if (EALUC == 4'b1000)
		EXALU = EXA << EXB[10:6];
	//shift right
	if (EALUC == 4'b1001)
		EXALU = EXA >> EXB[10:6];
	//add unsigned
	if (EALUC == 4'b0011)
		EXALU = EXA + EXB;
	//sub unsigned
	if (EALUC == 4'b1110)
		EXALU = EXA - EXB;
	//less than unsigned
	if (EALUC  == 4'b0101)
		EXALU = (EXA<EXB)? 1:0;
	//join
	if (EALUC == 4'b1111)
		EXALU = {EXB[15:0],16'b0};
	//jal
	if (EALUC == 4'b0100)
		EXALU = EXA;
	//nor
	if (EALUC == 4'b1010)
		EXALU = ~(EXA | EXB);
	
	//$display("# The ALU is RUNNING with 'h%h & 'h%h in OP 'b%b to RESULT 'h%h", EXA,EXB,EALUC,EXALU);
end

endmodule
