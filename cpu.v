`include "alu.v"
`include "controler.v"
module CPU();

parameter FINISHPC = 100000, MEMSIZE=1048576;
reg[31:0] 	i;
reg[7:0]	Mem[MEMSIZE-1:0], cache2[16383:0], cache1[1023:0];
reg[31:0]	cache1add, cache2add;
reg[31:0] 	PC, Regs[31:0],  // IMem[1023:0], DMem[1023:0], 
			IFIDIR, IFIDPC, IFIDPC4, 
			IDEXA, IDEXB, IDEXIMM,
			EXMEALU, EXMEB, 
			MEWBDATA, MEWBALU;
			
reg[4:0]	IDEXDES, EXMEDES, MEWBDES;

wire 		FIN, WPCIR, BRANCH, SMC, SMC2, DBP, DBPS,
			WREG, M2REG, WMEM, 
			ALUIMM, SHIFT,IDEQU, SEXT, REGRT, JUMP, JR, JAL;
reg			EWREG, EM2REG, EWMEM,  EALUIMM, ESHIFT,
			MWREG, MM2REG, MWMEM,
			WWREG, WM2REG;
wire[1:0]	FWDB, FWDA;
reg[3:0]	EALUC;
wire[3:0]	ALUC;

reg			EFIN, MEMbusy;
reg[31:0]	IFIRreg, MEDATAreg;
wire[31:0]	IFPC, IFPC4, IFIR, PCNEXT,
			IDPC,IDIR, IDPC4, IDA, IDB, PCBRANCH, IDIMM,
			EXA, EXB, EXIMM, EXALU, 
			MEALU, MEB, MEDATA,
			WBDATA, WBALU, WBWEDATA;
			
wire[4:0]	IDDES, EXDES, MEDES;

//do before
reg clock;
initial begin
for (i=0; i < MEMSIZE; i = i + 1) Mem[i] = {8{1'b0}};
for (i=0; i < 32; i = i + 1) Regs[i] = {32{1'b0}};
clock = 0;
EFIN = 0;
MEMbusy = 0;
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

$readmemb("test.mif",Mem);
cache1add = 0;
cache2add = 0;
//$display("# cache begin");
for (i=0; i < 16384; i = i + 1) cache2[i] = Mem[i];
for (i=0; i < 1024; i = i + 1) cache1[i] = Mem[i];
IFIRreg = {cache1[0], cache1[1] ,cache1[2] ,cache1[3]};
//TODO
end
always #2 if (MEMbusy==0 || clock==1) clock = (~clock); 

//IF
assign IFPC = PC;
assign IFPC4 = PC + 4;
assign IFIR = (SMC2)? IDEXB : IFIRreg;//{Mem[PC], Mem[PC+1], Mem[PC+2], Mem[PC+3]};//!
assign PCNEXT = (BRANCH)? PCBRANCH : ( ( (IFIR[31:26] == 'h4 || IFIR[31:26] == 'h5) && DBP)? IFPC4+( {{16{IFIR[15]}}, IFIR[15:0]} << 2) : IFPC4 );

//ID
assign IDPC = IFIDPC;
assign IDIR = IFIDIR;
assign IDPC4 = IFIDPC4;

assign IDA = (JAL)? IDPC4:((FWDA == 'b00)? ((IDIR[25:21]==0)?0:Regs[IDIR[25:21]]):(FWDA == 'b01)?EXALU:(FWDA == 'b10)?MEALU:MEDATA);
assign IDB = (FWDB == 'b00)? ((IDIR[20:16]==0)?0:Regs[IDIR[20:16]]):(FWDB == 'b01)?EXALU:(FWDB == 'b10)?MEALU:MEDATA;

assign IDEQU = (IDA == IDB)? 1:0;
assign PCBRANCH = (JR)? IDA:((JUMP)? ({IDPC4[31:28],IDIR[25:0]}<<2) : ((DBPS)?IDPC4+ ( {{16{IDIR[15]}}, IDIR[15:0]} << 2):IDPC4));
assign IDIMM = (SEXT)? {{16{1'b0}}, IDIR[15:0]} :{{16{IDIR[15]}}, IDIR[15:0]};

assign IDDES = (JAL)? 5'b11111 :((REGRT) ? IDIR[20:16] : IDIR[15:11]);

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

assign MEDATA = MEDATAreg;//{Mem[MEALU], Mem[MEALU+1] ,Mem[MEALU+2] ,Mem[MEALU+3]} ;//!

//WB
assign WBDATA = MEWBDATA;
assign WBALU = MEWBALU;
assign WBWEDATA = (WM2REG) ? WBDATA : WBALU ; 

//control
Controler Control(IDIR, MEDES, EXDES,IDEQU, EWREG, EM2REG, MWREG, MM2REG, WPCIR, BRANCH, WREG, M2REG, WMEM, ALUC, SHIFT, ALUIMM, SEXT, REGRT, FWDB, FWDA, JUMP, JR, JAL, EWMEM, EXALU, IFPC, IDPC ,SMC, SMC2, DBP ,DBPS, FIN);

integer handle;

always @(EFIN)
begin
	if (EFIN == 1) #200
	begin
	handle = $fopen("test.out");
	for (i = 0; i < 1024; i=i+1)
		cache2[ {cache1add[9:0],i[9:0]} % 16384 ] = cache1[i];
	for (i = 0; i < 16384; i=i+1)
		Mem[ {cache2add[5:0],i[13:0]}] = cache2[i];
	
	for (i = 0; i < 32; i = i + 1 )
	begin
		$display("%d in REG[%d]",Regs[i],i);
		$fdisplay(handle,"%b",Regs[i]);
	end
	
	for (i = 0; i < 40; i = i + 4 )
	begin
		
		$fdisplay(handle,"%b%b%b%b", Mem[i], Mem[i+1], Mem[i+2] ,Mem[i+3]);
	end
	for (i = 0; i < 40; i = i + 1 ) $display("%d in MEM[%d]",Mem[i],i);
	for (i = 524288; i < 524328; i = i + 4 )
	begin
		
		$fdisplay(handle,"%b%b%b%b", Mem[i], Mem[i+1], Mem[i+2] ,Mem[i+3]);
	end
	for (i = 524288; i < 524328; i = i + 1 ) $display("%d in MEM[%d]",Mem[i],i);
	$fclose(handle);
	$finish;
	end
end

always @(posedge clock)
begin
	
	$display("Time %0d! PC:%h, IDIR:%h, FWDA:%0b,FWDB:%0b", $time, PC, IDIR, FWDA,FWDB);
	//$display("Time %0d! PC:%0d!IDIR:%0h, rs %0d,rt %0d,IDA %0h,IDB %0h,IMM %0h,MEALU %0h,FWDA:%0b,FWDB:%0b,EWREG%0d,EXDES%0d ,ALUC %0b,EALUC,%0b,EXA %0h,EXB %0h,EXALU %0h,", $time, PC, IDIR,IDIR[25:21],IDIR[20:16],IDA,IDB,IDIMM,MEALU,FWDA,FWDB,EWREG,EXDES,ALUC,EALUC,EXA,EXB,EXALU);
	//$display("---");
	
	//IFID
	if (~WPCIR)	
	begin
		PC <=  PCNEXT;
		IFIDPC4 <=  IFPC4;
		IFIDPC <=  IFPC;
		if (~BRANCH) IFIDIR <=  IFIR; 
		else begin
			IFIDPC <=  {32{1'b1}};
			IFIDIR <=  {32{1'b0}};
			//$display("# BRANCH to 'h%h ,and IFIDIR will be flushed, DBP is %b", PCNEXT, DBP);
		end
		
	end
	if (WPCIR && SMC)
	begin
		//$display("# SMC: 'h%h change to 'h%h at PC 'h%h", IFIDIR, IDEXB , IDPC);
		IFIDIR <=  IDEXB;
		
	end
	//IDEX
	IDEXA <=  IDA;
	IDEXB <=  IDB;
	IDEXIMM <=  IDIMM;
	IDEXDES <=  IDDES;
	
	EFIN <= FIN;
	
	EWREG <=  WREG;
	EM2REG <=  M2REG;
	EWMEM <=  WMEM;
	EALUIMM <=  ALUIMM;
	ESHIFT <=  SHIFT;
	EALUC <=  ALUC;
	
	//EXME
	EXMEALU <=  EXALU;
	EXMEB <=  IDEXB; //important
	EXMEDES <=  EXDES;
	
	MWREG <=  EWREG;
	MM2REG <=  EM2REG;
	MWMEM <=  EWMEM;
	
	//MEWB
	MEWBDATA <=  MEDATA;
	MEWBALU <=  MEALU;
	MEWBDES <=  MEDES;
	
	WWREG <=  MWREG;
	WM2REG <=  MM2REG;
	
	i = #1 i;
	//write
	if (WWREG) 
	begin
		$display("# Store 'h%h in REG[%d]",WBWEDATA,MEWBDES);
		Regs[MEWBDES] <=  WBWEDATA;
	end
	
	if (MWMEM)
	begin	
		$display("# Store 'h%h in MEM[%h]",MEB,MEALU>>2);
		begin
			//write
			MEMbusy = 1;
			if (cache1add == MEALU / 1024) 
			begin
				//$display("# write in cache1");
				{cache1[MEALU%1024], cache1[MEALU%1024+1] ,cache1[MEALU%1024+2] ,cache1[MEALU%1024+3]} = #3 MEB;
			end
			else
				if (cache2add == MEALU / 16384) 
				begin
					//$display("# write in cache2");
					{cache2[MEALU%16384], cache2[MEALU%16384+1] ,cache2[MEALU%16384+2] ,cache2[MEALU%16384+3]} = #5 MEB;
				end
				else
					{Mem[MEALU], Mem[MEALU+1] ,Mem[MEALU+2] ,Mem[MEALU+3]} =#10  MEB;
			//MEMbusy = 0;
		end
	end
	
	//i = #1 i;
	//read
	if (MM2REG ==1)
		begin
			//read
			MEMbusy = 1;
			if (cache1add == MEALU / 1024) 
			begin
				//$display("# read in cache1 #2");
				MEDATAreg = #3 {cache1[MEALU%1024], cache1[MEALU%1024+1] ,cache1[MEALU%1024+2] ,cache1[MEALU%1024+3]};
			end
			else
			begin
				for (i = 0; i < 1024; i=i+1)
					cache2[ {cache1add[9:0],i[9:0]} % 16384 ] = cache1[i];
				if (cache2add == MEALU / 16384) 
				begin
					//$display("# read in cache2 #2");
					MEDATAreg = #5 {cache2[MEALU%16384], cache2[MEALU%16384+1] ,cache2[MEALU%16384+2] ,cache2[MEALU%16384+3]};
				end
				else
					begin
						for (i = 0; i < 16384; i=i+1)
							Mem[ {cache2add[5:0],i[13:0]}] = cache2[i];
						MEDATAreg = #10 {Mem[MEALU], Mem[MEALU+1] ,Mem[MEALU+2] ,Mem[MEALU+3]};
						//$display("# cache2 fresh");
						cache2add = MEALU / 16384;
						for (i = 0; i < 16384; i=i+1)
							 cache2[i] = Mem[ {cache2add[5:0],i[13:0]}];
					end//cache2
				//$display("# cache1 fresh");
				cache1add = MEALU / 1024;
				for (i = 0; i < 1024; i=i+1)
					 cache1[i] = cache2[ {cache1add[9:0],i[9:0]} % 16384 ];
			end//cache1
			//MEMbusy = 0;
			//$display("MEDATAreg %h, MEALU %h", MEDATAreg,MEALU);
		end
		
			MEMbusy = 1;
			if (cache1add == PC / 1024) 
			begin
				//$display("# read in cache1");
				IFIRreg = #3 {cache1[PC%1024], cache1[PC%1024+1] ,cache1[PC%1024+2] ,cache1[PC%1024+3]};
			end
			else
			begin
				for (i = 0; i < 1024; i=i+1)
					cache2[ {cache1add[9:0],i[9:0]} % 16384 ] = cache1[i];
				if (cache2add == PC / 16384) 
				begin
					//$display("# read in cache2");
					IFIRreg = #5 {cache2[PC%16384], cache2[PC%16384+1] ,cache2[PC%16384+2] ,cache2[PC%16384+3]};
				end
				else
					begin
						for (i = 0; i < 16384; i=i+1)
							Mem[ {cache2add[5:0],i[13:0]}] = cache2[i];
						IFIRreg = #10 {Mem[PC], Mem[PC+1] ,Mem[PC+2] ,Mem[PC+3]};
						//$display("# cache2 fresh");
						cache2add = PC / 16384;
						for (i = 0; i < 16384; i=i+1)
							 cache2[i] = Mem[ {cache2add[5:0],i[13:0]}];
					end//cache2
				//$display("# cache1 fresh");
				cache1add = PC / 1024;
				for (i = 0; i < 1024; i=i+1)
					 cache1[i] = cache2[ {cache1add[9:0],i[9:0]} % 16384 ];
			end//cache1
			MEMbusy = 0;
		//$display("IFIRreg %h", IFIRreg);
	i = #1 i;
end

always @(negedge clock)
begin
	
end

endmodule

		

