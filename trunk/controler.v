module Controler(IDIR, MEDES, EXDES,IDEQU, EWREG, EM2REG, MWREG, MM2REG, WPCIR, BRANCH, WREG, M2REG, WMEM, ALUC, SHIFT, ALUIMM, SEXT, REGRT, FWDB, FWDA, JUMP, JR, JAL, EWMEM, EXALU, IDPC ,SMC);

input[31:0]	IDIR, EXALU, IDPC;
input[4:0]	MEDES, EXDES;
input 		IDEQU, EWREG, EM2REG, MWREG, MM2REG, EWMEM;

output		WPCIR, BRANCH, WREG, M2REG, WMEM,SHIFT, ALUIMM, SEXT, REGRT, JUMP, JR, JAL, SMC;
output[1:0]	FWDB, FWDA;
output[3:0]	ALUC;
reg			WPCIR, BRANCH, WREG, M2REG, WMEM,SHIFT, ALUIMM, SEXT, REGRT, JUMP, JR, JAL, SMC;
reg[1:0]	FWDB, FWDA;
reg[3:0]	ALUC;

wire[5:0]	op,funct;
wire[4:0]	rs, rt,shamt;
wire[15:0]	imm;

assign op = IDIR[31:26];
assign funct = IDIR[5:0];
assign rs = IDIR[25:21];
assign rt = IDIR[20:16];
assign imm = IDIR[15:0];


always	@(op, funct, rs, rt, imm, MEDES, EXDES,IDEQU, EWREG, EM2REG, MWREG, MM2REG)
begin
	//$display("Time %0d:IDIR%h op%h funct%h rs%h rt%h imm%h MEDES%h EXDES%h IDEQU%h EWREG%h EM2REG%h MWREG%h MM2REG%h WPCIR%h BRANCH%h WREG%h M2REG%h WMEM%h ALUC%h SHIFT%h ALUIMM%h SEXT%h REGRT%h FWDB%h FWDA%h JUMP%h JR%h",$time,IDIR,op,funct,rs,rt,imm,MEDES, EXDES,IDEQU, EWREG, EM2REG, MWREG, MM2REG, WPCIR, BRANCH, WREG, M2REG, WMEM, ALUC, SHIFT, ALUIMM, SEXT, REGRT, FWDB, FWDA, JUMP,JR);
	WPCIR = 0;
	BRANCH = 0;
	WREG = 0;
	M2REG = 0;
	WMEM = 0;
	FWDA = 'b00;
	FWDB = 'b00;
	SHIFT = 0;
	ALUIMM = 0;
	SEXT = 0;
	REGRT = 0;
	JUMP = 0;
	JR = 0;
	JAL = 0;
	SMC = 0;
	
	case (op)
		'h0: begin //do with function
			
			//forward
			if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
			if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
			if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
			if (MWREG && (rt != 0) && (rt == MEDES)) FWDB = 'b10;
			if (EWREG && (rt != 0) && (rt == EXDES)) FWDB = 'b01;
			if (MWREG && MM2REG && (rt != 0) && (rt == MEDES)) FWDB = 'b11;
			
			case (funct)	
			
				6'h00:begin//shift left
				WREG = 1;
				ALUC = 'b1000;
				ALUIMM = 1;
				end
				
				6'h02:begin//shift right
				WREG = 1;
				ALUC = 'b1001;
				ALUIMM = 1;
				end
				
				6'h20:begin//add
				WREG = 1;
				ALUC = 'b0010;
				end
				
				6'h20:begin//add unsigned
				WREG = 1;
				ALUC = 'b0011;
				end
				
				6'h24:begin//and
				WREG = 1;
				ALUC = 'b0000;
				end
				
				6'h27:begin//nor
				WREG = 1;
				ALUC = 'b1010;
				end
				
				6'h25:begin//or
				WREG = 1;
				ALUC = 'b0001;
				end
				
				6'h2a:begin//set less than
				WREG = 1;
				ALUC = 'b0111;
				end
				
				6'h2b:begin//set less than unsigned
				WREG = 1;
				ALUC = 'b0101;
				end
				
				6'h22:begin//subtract
				WREG = 1;
				ALUC = 'b0110;
				end
				
				6'h22:begin//subtract unsigned
				WREG = 1;
				ALUC = 'b1110;
				end
				
				6'h08:begin//jump register
				JR = 1;
				BRANCH = 1;
				end
				
				default:begin
				end	
			endcase	
			//stall
			if (EWREG && EM2REG && (((rs != 0) && (rs == EXDES)) || ((rt != 0) && (rt == EXDES))) )
			begin
				WPCIR = 1;
				WREG = 0;
				M2REG = 0;
				WMEM = 0;
				JR = 0;
				//BRANCH = 0;
			end					
		end
		
		'h8: begin //add immediate
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0010;
		ALUIMM = 1;
		REGRT = 1;
		
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'h9: begin //add immediate unsigned
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0011;
		ALUIMM = 1;
		REGRT = 1;
		
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'hc: begin//and immediate
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0000;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 1;
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'h4:begin //branch on equal
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		if (MWREG && (rt != 0) && (rt == MEDES)) FWDB = 'b10;
		if (EWREG && (rt != 0) && (rt == EXDES)) FWDB = 'b01;
		if (MWREG && MM2REG && (rt != 0) && (rt == MEDES)) FWDB = 'b11;
		
		if (IDEQU)
		begin
			BRANCH = 1;
			JUMP = 0;
		end
		//stall
		if (EWREG && EM2REG && (((rs != 0) && (rs == EXDES)) || ((rt != 0) && (rt == EXDES))) )
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'h5:begin //branch on not equal
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		if (MWREG && (rt != 0) && (rt == MEDES)) FWDB = 'b10;
		if (EWREG && (rt != 0) && (rt == EXDES)) FWDB = 'b01;
		if (MWREG && MM2REG && (rt != 0) && (rt == MEDES)) FWDB = 'b11;
		
		if (~IDEQU)
		begin
			BRANCH = 1;
			JUMP = 0;
		end
		//stall
		if (EWREG && EM2REG && (((rs != 0) && (rs == EXDES)) || ((rt != 0) && (rt == EXDES))) )
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'h2:begin //jump
		JUMP = 1;
		BRANCH = 1;
		end
		
		'h3:begin //jump and link
		 JUMP = 1;
		 BRANCH = 1;
		 JAL = 1;
		 ALUC = 'b0100;
		 WREG = 1;
		 end
		
		'h23:begin//load word
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		M2REG = 1;
		ALUC = 'b0010;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 0;
		
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'hd:begin//or immediate
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0001;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 1;
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'ha:begin//set less than immediate
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0111;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 0;
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'hb:begin//set less than immediate unsigned
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		WREG = 1;
		ALUC = 'b0101;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 0;
		//stall
		if (EWREG && EM2REG && (rs != 0) && (rs == EXDES))
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'h2b:begin //store word
		//forward
		if (MWREG && (rs != 0) && (rs == MEDES)) FWDA = 'b10;
		if (EWREG && (rs != 0) && (rs == EXDES)) FWDA = 'b01;
		if (MWREG && MM2REG && (rs != 0) && (rs == MEDES)) FWDA = 'b11;
		
		if (MWREG && (rt != 0) && (rt == MEDES)) FWDB = 'b10;
		if (EWREG && (rt != 0) && (rt == EXDES)) FWDB = 'b01;
		if (MWREG && MM2REG && (rt != 0) && (rt == MEDES)) FWDB = 'b11;
		
		WREG = 0;
		WMEM = 1;
		ALUC = 'b0010;
		ALUIMM = 1;
		
		//stall
		if (EWREG && EM2REG && (((rs != 0) && (rs == EXDES)) || ((rt != 0) && (rt == EXDES))) )
		begin
			WPCIR = 1;
			WREG = 0;
			M2REG = 0;
			WMEM = 0;
		end
		end
		
		'hf:begin//load upper imm
				
		WREG = 1;
		ALUC = 'b1111;
		ALUIMM = 1;
		REGRT = 1;
		SEXT = 0;
		
		end
		
		default:begin
		end
	endcase	
	//SMC
	if (EWMEM && (IDPC == EXALU))
	begin
		SMC = 1;
		WPCIR = 1;
		WREG = 0;
		M2REG = 0;
		WMEM = 0;
	end
		
end
endmodule


module CtrlALU(op, func, opcode);
input[5:0] op, func;
output[3:0] opcode;
reg[3:0] opcode;

always @(op or func)
begin

if (op == 0)
begin
	if (func == 'h20) opcode = 'b0010;
	if (func == 'h24) opcode = 'b0000;
	if (func == 'h23) opcode = 'b0010;
	if (func == 'h25) opcode = 'b0001;
	if (func == 'h2a) opcode = 'b0111;
	if (func == 'h22) opcode = 'b0110;
end

if (op == 'h8) opcode = 'b0010;
if (op == 'hc) opcode = 'b0000;
if (op == 'hd) opcode = 'b0001;
if (op == 'ha) opcode = 'b0111;
if (op == 'h2b) opcode = 'b0010;

end

endmodule
