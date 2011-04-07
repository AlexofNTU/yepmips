`include "alu.v"
`include "controler.v"
module CPU ();

parameter FINISHPC = 131071;

reg[31:0] 	PC, Regs[31:0], Mem[262143:0], // IMem[1023:0], DMem[1023:0], 
			IFIDIR, IFIDPC4, 
			IDEXA, IDEXB, IDEXIMM,
			EXMEALU, EXMEB, 
			MEWBDATA, MEWBALU;
			
reg[4:0]	IDEXDES, EXMEDES, MEWBDES;

wire 		WPCIR, BRANCH, 
			WREG, M2REG, WMEM, 
			ALUIMM, SHIFT,IDEQU, SEXT, REGRT, JUMP;
reg			EWREG, EM2REG, EWMEM,  EALUIMM, ESHIFT,
			MWREG, MM2REG, MWMEM,
			WWREG, WM2REG;
wire[1:0]	FWDB, FWDA;
reg[3:0]	EALUC;
wire[3:0]	ALUC;

wire[31:0]	IFPC, IFPC4, IFIR, PCNEXT,
			IDIR, IDPC4, IDA, IDB, PCBRANCH, IDIMM,
			EXA, EXB, EXIMM, EXALU, 
			MEALU, MEB, MEDATA,
			WBDATA, WBALU, WBWEDATA;
			
wire[4:0]	IDDES, EXDES, MEDES;

//do before
reg clock,microclock;
initial begin
clock = 0;
microclock = 0;
PC = 0;
IFIDIR = {32{1'b0}};
EWREG = 0;
EM2REG = 0;
EWMEM = 0;
MWREG = 0;
MM2REG = 0;
MWMEM = 0;
WWREG = 0;
WM2REG = 0;

$readmemh("mem.txt",Mem);
//TODO
end
always #2 clock = (~clock); 
always #1 microclock = (~microclock);

//IF
assign IFPC = PC;
assign IFPC4 = PC + 4;
assign IFIR = Mem[PC>>2];
assign PCNEXT = (BRANCH)? PCBRANCH : IFPC4;

//ID
assign IDIR = IFIDIR;
assign IDPC4 = IFIDPC4;

assign IDA = (FWDA == 'b00)? ((IDIR[25:21]==0)?0:Regs[IDIR[25:21]]):(FWDA == 'b01)?EXALU:(FWDA == 'b10)?MEALU:MEDATA;
assign IDB = (FWDB == 'b00)? ((IDIR[20:16]==0)?0:Regs[IDIR[20:16]]):(FWDB == 'b01)?EXALU:(FWDB == 'b10)?MEALU:MEDATA;

assign IDEQU = (IDA == IDB)? 1:0;
assign PCBRANCH = (JUMP)? ({IDPC4[31:28],IDIR[25:0]}<<2) : IDPC4+ ( {{16{IDIR[15]}}, IDIR[15:0]} << 2);
assign IDIMM = (SEXT)? {{16{1'b0}}, IDIR[15:0]} :{{16{IDIR[15]}}, IDIR[15:0]};

assign IDDES = (REGRT) ? IDIR[20:16] : IDIR[15:11];

//EX
assign EXA = IDEXA;//(ESHITF)?EXIMM:
assign EXIMM = IDEXIMM;
assign EXB = (EALUIMM) ? EXIMM : IDEXB;

ALU MAINALU(EALUC, EXA, EXB, EXALU);

assign EXDES = IDEXDES;

//MEM
assign MEALU = EXMEALU;
assign MEB = EXMEB;

assign MEDES = EXMEDES;

assign MEDATA = Mem[MEALU>>2];

//WB
assign WBDATA = MEWBDATA;
assign WBALU = MEWBALU;
assign WBWEDATA = (WM2REG) ? WBDATA : WBALU ; 

//control
Controler Control(IDIR, MEDES, EXDES,IDEQU, EWREG, EM2REG, MWREG, MM2REG, WPCIR, BRANCH, WREG, M2REG, WMEM, ALUC, SHIFT, ALUIMM, SEXT, REGRT, FWDB, FWDA, JUMP);

always @(posedge clock)
begin
	if (PC > FINISHPC) $finish;
	$display("Time %0d! PC:%0d!IDIR:%0h,Mem[131072]:%0d ,reg8:%0d,reg9:%0d,rs %0d,rt %0d,IDA %0h,IDB %0h,IMM %0h,MEALU %0h,FWDA:%0b,FWDB:%0b,EWREG%0d,EXDES%0d ,ALUC %0b,EALUC,%0b,EXA %0h,EXB %0h,EXALU %0h,", $time, PC, IDIR, Mem[131072], Regs[8],Regs[9],IDIR[25:21],IDIR[20:16],IDA,IDB,IDIMM,MEALU,FWDA,FWDB,EWREG,EXDES,ALUC,EALUC,EXA,EXB,EXALU);
	$display("---");
	//IFID
	if (~WPCIR)	
	begin
		PC <= #1 PCNEXT;
		if (~BRANCH) IFIDIR <= #1 IFIR; else IFIDIR <= #1 {32{1'b0}};
		IFIDPC4 <= #1 IFPC4;
	end
	
	//IDEX
	IDEXA <= #1 IDA;
	IDEXB <= #1 IDB;
	IDEXIMM <= #1 IDIMM;
	IDEXDES <= #1 IDDES;
	
	EWREG <= #1 WREG;
	EM2REG <= #1 M2REG;
	EWMEM <= #1 WMEM;
	EALUIMM <= #1 ALUIMM;
	ESHIFT <= #1 SHIFT;
	EALUC <= #1 ALUC;
	
	//EXME
	EXMEALU <= #1 EXALU;
	EXMEB <= #1 IDEXB; //important
	EXMEDES <= #1 EXDES;
	
	MWREG <= #1 EWREG;
	MM2REG <= #1 EM2REG;
	MWMEM <= #1 EWMEM;
	
	//MEWB
	MEWBDATA <= #1 MEDATA;
	MEWBALU <= #1 MEALU;
	MEWBDES <= #1 MEDES;
	
	WWREG <= #1 MWREG;
	WM2REG <= #1 MM2REG;
	
end

always @(negedge clock)
begin
	if (WWREG) 
	begin
		$display("# Store 'h%0h in REG[%0d]",WBWEDATA,MEWBDES);
		Regs[MEWBDES] <= #1 WBWEDATA;
	end
	if (MWMEM)
	begin	
		$display("# Store 'h%0h in MEM[%0h]",MEB,MEALU>>2);
		Mem[MEALU>>2] <= #1 MEB;
	end
end

endmodule

		

