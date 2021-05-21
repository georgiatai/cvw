
module fctrl (
  input  logic [6:0] Funct7D,
  input  logic [6:0] OpD,
  input  logic [4:0] Rs2D,
  input  logic [2:0] Funct3D,
  input  logic [2:0] FRM_REGW,
  output logic       IllegalFPUInstrD,
  output logic       FRegWriteD,
  output logic       DivSqrtStartD,
  //output logic [2:0] regSelD,
  output logic [2:0] FResultSelD,
  output logic [3:0] OpCtrlD,
  output logic       FmtD,
  output logic [2:0] FrmD,
  output logic [1:0] FMemRWD,
  output logic       OutputInput2D,
  output logic       FWriteIntD);


  logic IllegalFPUInstr1D, IllegalFPUInstr2D;
  //precision is taken directly from instruction
  assign FmtD = Funct7D[0];
  // *** fix rounding for dynamic rounding
  assign FrmD = &Funct3D ? FRM_REGW : Funct3D;

  //all subsequent logic is based on the table present
  //in Section 5 of Wally Architecture Specification
  
  //write is enabled for all fp instruciton op codes
  //sans fp load
  logic isFP, isFPLD;
  always_comb begin
	//case statement is easier to modify
	//in case of errors
	case(OpD)
		//fp instructions sans load
		7'b1010011 : isFP = 1'b1;
		7'b1000011 : isFP = 1'b1;
		7'b1000111 : isFP = 1'b1;
		7'b1001011 : isFP = 1'b1;
		7'b1001111 : isFP = 1'b1;
		7'b0100111 : isFP = 1'b1;
		7'b0000111 : isFP = 1'b1;// KEP change 7'b1010011 to 7'b0000111
		default    : isFP = 1'b0;
	endcase
  end
  

  
  //useful intermediary signals
  //
  //(mult only not supported in current datapath)
  //set third FMA operand to zero in this case
  //(or equivalent)

  always_comb begin
	//checks all but FMA/store/load
  IllegalFPUInstr2D = 0;
	if(OpD == 7'b1010011) begin
  		casez(Funct7D)
			//compare	
			7'b10100?? : FResultSelD = 3'b001;
			//div/sqrt
			7'b0?011?? : FResultSelD = 3'b000;
			//add/sub
			7'b0000??? : FResultSelD = 3'b100;
			//mult
			7'b00010?? : FResultSelD = 3'b010;
			//convert (not precision)
			7'b110?0?? : FResultSelD = 3'b100;
			//convert (precision)
			7'b010000? : FResultSelD = 3'b100;
			//Min/Max
			7'b00101?? : FResultSelD = 3'b001;
			//sign injection
			7'b00100?? : FResultSelD = 3'b011;
			//classify //only if funct3 = 001 
			7'b11100?? : if(Funct3D == 3'b001) FResultSelD = 3'b101;
			//output ReadData1
                   else if (Funct7D[1] == 0) FResultSelD = 3'b111;
			//output SrcW
			7'b111100? : FResultSelD = 3'b110;
			default    : begin FResultSelD = 3'b0; IllegalFPUInstr2D = 1'b1; end
		endcase
	end
	//FMA/store/load
	else begin
  		case(OpD)
			//4 FMA instructions
			7'b1000011 : FResultSelD = 3'b010;
			7'b1000111 : FResultSelD = 3'b010;
			7'b1001011 : FResultSelD = 3'b010;
			7'b1001111 : FResultSelD = 3'b010;
			//store
			7'b0100111 : FResultSelD = 3'b111;
			//load
			7'b0000111 : FResultSelD = 3'b111;
			default    : begin FResultSelD = 3'b0; IllegalFPUInstr2D = 1'b1; end
		endcase
	end
  end

  assign OutputInput2D = OpD == 7'b0100111;

  assign FMemRWD[0] = OutputInput2D;
  assign FMemRWD[1] = OpD == 7'b0000111;



  //register is chosen based on operation performed
  //---- 
  //write selection is chosen in the same way as 
  //register selection
  //

  // reg/write sel logic and assignment
  // 
  // 3'b000 = div/sqrt
  // 3'b001 = cmp
  // 3'b010 = fma/mult
  // 3'b011 = sgn inj
  // 3'b100 = add/sub/cnvt
  // 3'b101 = classify
  // 3'b110 = output SrcAW
  // 3'b111 = output ReadData1
  //
  //reg select
  
  //this value is used enough to be shorthand

  //if op is div/sqrt - start div/sqrt
  assign DivSqrtStartD = ~|FResultSelD; // is FResultSelD == 000

  //operation control for each fp operation
  //has to be expanded over standard to account for
  //integrated fpadd/cvt
  //
  //will integrate FMA opcodes into design later
  //
  //conversion instructions will
  //also need to be added later as I find the opcode
  //version I used for this repo

  //let's do separate SOP for each type of operation
//  assign OpCtrlD[3] = 1'b0;
//
//


 
  always_comb begin
    IllegalFPUInstr1D = 0;
    case (FResultSelD)
      // div/sqrt
      //  fdiv  = ???0
      //  fsqrt = ???1
      3'b000 : OpCtrlD = {3'b0, Funct7D[5]};
      // cmp		
      //  fmin = ?100
      //  fmax = ?101
      //  feq  = ?010
      //  flt  = ?001
      //  fle  = ?011
      //		   {?,    is min or max, is eq or le, is lt or le}
      3'b001 : OpCtrlD = {1'b0, Funct7D[2], ~Funct3D[0], ~(|Funct3D[2:1])};
      //fma/mult	
      //  fmadd  = ?000
      //  fmsub  = ?001
      //  fnmadd = ?010
      //  fnmsub = ?011
      //  fmul   = ?100
      //		  {?, is mul, is negitive, is sub}
      3'b010 : OpCtrlD = {1'b0, OpD[4:2]};
      // sgn inj
      //  fsgnj  = ??00
      //  fsgnjn = ??01
      //  fsgnjx = ??10
      3'b011 : OpCtrlD = {2'b0, Funct3D[1:0]};
      // add/sub/cnvt
      //  fadd      = 0000
      //  fsub      = 0001
      //  fcvt.w.s  = 0100
      //  fcvt.wu.s = 0101
      //  fcvt.s.w  = 0110
      //  fcvt.s.wu = 0111
      //  fcvt.s.d  = 0010
      //  fcvt.w.d  = 1100
      //  fcvt.wu.d = 1101
      //  fcvt.d.w  = 1110
      //  fcvt.d.wu = 1111
      //  fcvt.d.s  = 1000
      //		   { is double and not add/sub, is to/from int, is to int or float to double,      is unsigned or sub
      3'b100 : OpCtrlD = {Funct7D[0]&Funct7D[5], Funct7D[6], Funct7D[3] | (~Funct7D[6]&Funct7D[5]&~Funct7D[0]), Rs2D[0]|(Funct7D[2]&~Funct7D[5])};
      // classify	  {?, ?, ?, ?}
      3'b101 : OpCtrlD = 4'b0;
      // output SrcAW
      //  fmv.w.x = ???0
      //  fmv.w.d = ???1
      3'b110 : OpCtrlD = {3'b0, Funct7D[0]};
      // output Input1
      //  flw       = ?000
      //  fld       = ?001 
      //  fsw       = ?010 // output Input2
      //  fsd       = ?011 // output Input2
      //  fmv.x.w  = ?100
      //  fmv.d.w  = ?101
      //		   {?, is mv, is store, is double or fcvt.d.w}
      3'b111 : OpCtrlD = {1'b0, OpD[6:5], Funct3D[0] | (OpD[6]&Funct7D[0])};
      default : begin OpCtrlD = 4'b0; IllegalFPUInstr1D = 1'b1; end
    endcase
  end

  assign IllegalFPUInstrD = IllegalFPUInstr1D | IllegalFPUInstr2D;
  //write to integer source if conv to int occurs
  //AND of Funct7 for int results 
  //			is add/cvt       and  is to int  or is classify		 or     is cmp	       	and not max/min or is output ReadData1 and is mv
  assign FWriteIntD = ((FResultSelD == 3'b100)&Funct7D[3]) | (FResultSelD == 3'b101) | ((FResultSelD == 3'b001)&~Funct7D[2]) | ((FResultSelD == 3'b111)&OpD[6]);
  // 		      if not writting to int reg and not a store function and not move
  assign FRegWriteD = ~FWriteIntD & ~OpD[5] & ~((FResultSelD == 3'b111)&OpD[6]) & isFP;
endmodule
