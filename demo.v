module CPU (clock);
parameter LW = 6'b100011, SW = 6'b101011, BEQ=6'b000100, no-op = 32'b00000000000000000000000000100000, ALUop=6'b000000;
input clock;
   reg[31:0] PC, Regs[0:31], IMemory[1023:0], DMemory[1023:0], // separate memories
                  IFIDIR, IDEXA, IDEXB, IDEXIR, EXMEMIR, EXMEMB, // pipeline registers
                  EXMEMALUOut, MEMWBValue, MEMWBIR; // pipeline registers
   wire [4:0] IDEXrs, IDEXrt, EXMEMrd, MEMWBrd; //hold register fields
   wire [5:0] EXMEMop, MEMWBop, IDEXop; //Hold opcodes
   wire [31:0] Ain, Bin;
// declare the bypass signals 
   wire takebranch, stall, bypassAfromMEM, bypassAfromALUinWB,bypassBfromMEM, bypassBfromALUinWB,
        bypassAfromLWinWB, bypassBfromLWinWB; 
   assign IDEXrs = IDEXIR[25:21];    assign IDEXrt = IDEXIR[15:11];    assign EXMEMrd = EXMEMIR[15:11]; 
   assign MEMWBrd = MEMWBIR[20:16]; assign EXMEMop = EXMEMIR[31:26];    
   assign MEMWBop = MEMWBIR[31:26];  assign IDEXop = IDEXIR[31:26];
   // The bypass to input A from the MEM stage for an ALU operation
   assign bypassAfromMEM = (IDEXrs == EXMEMrd) & (IDEXrs!=0) & (EXMEMop==ALUop); // yes, bypass
   // The bypass to input Bfrom the MEM stage for an ALU operation
   assign bypassBfromMEM = (IDEXrt== EXMEMrd)&(IDEXrt!=0) & (EXMEMop==ALUop); // yes, bypass
   // The bypass to input A from the WB stage for an ALU operation
   assign bypassAfromALUinWB =( IDEXrs == MEMWBrd) & (IDEXrs!=0) & (MEMWBop==ALUop); 
   // The bypass to input B from the WB stage for an ALU operation
   assign bypassBfromALUinWB = (IDEXrt==MEMWBrd) & (IDEXrt!=0) & (MEMWBop==ALUop); //
   // The bypass to input A from the WB stage for an LW operation
   assign bypassAfromLWinWB =( IDEXrs ==MEMWBIR[20:16]) & (IDEXrs!=0) & (MEMWBop==LW); 
   // The bypass to input B from the WB stage for an LW operation
   assign bypassBfromLWinWB = (IDEXrt==MEMWBIR[20:16]) & (IDEXrt!=0) & (MEMWBop==LW); 
   // The A input to the ALU is bypassed from MEM if there is a bypass there, 
   // Otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register
   assign Ain = bypassAfromMEM? EXMEMALUOut :
                       (bypassAfromALUinWB | bypassAfromLWinWB)? MEMWBValue : IDEXA;
   // The B input to the ALU is bypassed from MEM if there is a bypass there, 
   // Otherwise from WB if there is a bypass there, and otherwise comes from the IDEX register
   assign Bin = bypassBfromMEM? EXMEMALUOut :
                       (bypassBfromALUinWB | bypassBfromLWinWB)? MEMWBValue: IDEXB;
// The signal for detecting a stall based on the use of a result from LW
   assign stall = (MEMWBIR[31:26]==LW) && // source instruction is a load
            ((((IDEXop==LW)|(IDEXop==SW)) && (IDEXrs==MEMWBrd)) | // stall for address calc
((IDEXop==ALUop) && ((IDEXrs==MEMWBrd)|(IDEXrt==MEMWBrd)))); // ALU use
// Signal for a taken branch: instruction is BEQ and registers are equal
assign takebranch = (IFIDIR[31:26]==BEQ) && (Regs[IFIDIR[25:21]]== Regs[IFIDIR[20:16]]); 
   reg [5:0] i; //used to initialize registers 
   initial begin  
       PC = 0; 
      IFIDIR=no-op; IDEXIR=no-op; EXMEMIR=no-op; MEMWBIR=no-op; // put no-ops in pipeline registers
       for (i=0;i<=31;i=i+1) Regs[i] = i; //initialize registers--just so they aren¡¯t don¡¯t cares
   end
   always @ (posedge clock) begin 
   if (~stall) begin // the first three pipeline stages stall if there is a load hazard
      if (~takebranch) begin     // first instruction  in the pipeline is being fetched normally
          IFIDIR <= IMemory[PC>>2]; 
          PC <= PC + 4;
      end else begin // a taken branch is in ID; instruction in IF is wrong; insert a no-op and reset the PC
         IFDIR <= no-op; 
         PC <= PC + ({{16{IFIDIR[15]}}, IFIDIR[15:0]}<<2); 
         end 
      // second instruction is in register fetch 
       IDEXA <= Regs[IFIDIR[25:21]]; IDEXB <= Regs[IFIDIR[20:16]]; // get two registers
      // third instruction is doing address calculation or ALU operation
         IDEXIR <= IFIDIR;  //pass along IR
if ((IDEXop==LW) |(IDEXop==SW))  // address calculation & copy B
                   EXMEMALUOut <= IDEXA +{{16{IDEXIR[15]}}, IDEXIR[15:0]}; 
         else if (IDEXop==ALUop) case (IDEXIR[5:0]) //case for the various R-type instructions
                 32: EXMEMALUOut <= Ain + Bin;  //add operation
                 default: ; //other R-type operations: subtract, SLT, etc.
               endcase
       EXMEMIR <= IDEXIR; EXMEMB <= IDEXB; //pass along the IR & B register
     end
   else EXMEMIR <= no-op; //Freeze first three stages of pipeline; inject a nop into the EX output
      //Mem stage of pipeline
       if (EXMEMop==ALUop) MEMWBValue <= EXMEMALUOut; //pass along ALU result
          else if (EXMEMop == LW) MEMWBValue <= DMemory[EXMEMALUOut>>2]; 
            else if (EXMEMop == SW) DMemory[EXMEMALUOut>>2] <=EXMEMB; //store 
      // the WB stage
MEMWBIR <= EXMEMIR; //pass along IR
      if ((MEMWBop==ALUop) & (MEMWBrd != 0)) Regs[MEMWBrd] <= MEMWBValue; // ALU operation
      else if ((EXMEMop == LW)& (MEMWBIR[20:16] != 0)) Regs[MEMWBIR[20:16]] <= MEMWBValue;
   end
endmodule