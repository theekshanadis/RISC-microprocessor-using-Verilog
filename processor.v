module processor; 

	reg clk;
	wire [16:1]insout;
	reg load;
	reg [15:0]insload;
	reg [15:0]laddr;
	wire [15:0]pcaddr;
	wire c_load;
	reg clear;
	wire [15:0] w_write;
	wire [15:0] A,B;
	wire [15:0]m0_out;
	wire [15:0]i2,i3;
	wire c_m0,cout,lt,eq,gt,overf;
	wire cout1,lt1,eq1,gt1,overf1;
	wire [15:0]w_extend,reginput;
	wire [15:0]alu0_out;
	wire [2:0] c_alu0;
	wire [15:0]mem_out;
	wire memread,memwrite,c_and,c_m2,c_m3,cload;
	wire [15:0]m2_out;
	wire [15:0] alu1_out,alu2_out,m3_out,jump_out;
	reg [15:0] reg_load;
	reg [3:0]reg_addr;
	wire [3:0]regload,iMe1,iMe2;
	reg loadreg;
	MUX4bit Me0(regload,insout[4:1],reg_addr,iMe1, iMe2, 1'b0,loadreg);
	MUX Me(w_write,reginput,reg_load, i2, i3, 1'b0,loadreg);
	or g2(c_load,loadreg,cload);
	pc progcounter(pcaddr,m2_out,clk);
	insmemory insfetch(insout,insload,laddr,pcaddr,load,clk);
	registerfile reg_file(A,B,insout[12:9],insout[8:5],regload,w_write,c_load,clear,clk);
	MUX M0(m0_out, B,w_extend, i2, i3, 1'b0, c_m0);
	signextender wordextend(w_extend,insout[4:1]);
	alu alu0(alu0_out,cout,lt,eq,gt,overf,A,m0_out,1'b0,c_alu0);
	memory datamem(mem_out,alu0_out,B,memread,memwrite,clk);
	MUX M1(reginput,mem_out,alu0_out, i2, i3, 1'b0, c_m1);
	alu alu1(alu1_out,cout1,lt1,eq1,gt1,overf1,pcaddr,16'd2,1'b0,3'b010);
	alu alu2(alu2_out,cout1,lt1,eq1,gt1,overf1,alu1_out,w_extend,1'b0,3'b010);
	MUX M3(m3_out,alu1_out,alu2_out, i2, i3, 1'b0, c_and);
	and (c_and ,~eq ,c_m3);
	MUX M2(m2_out,m3_out,jump_out, i2, i3, 1'b0, c_m2);
	jump jumpins(jump_out,insout[12:1],pcaddr[15:13]);
	controller maincontroller({c_m2,c_m1,c_m0},c_m3,c_alu0,memread,memwrite,cload,insout[16:13],clk);

//clock module (time period is 10 time units)
	initial
		clk = 1'b0;
	always
	begin
	#5 clk = ~clk;
	end
initial 
begin
	#4 insload = 16'b0010_0000_0001_0011;load = 1'b1;laddr = 16'd0;loadreg = 1'b1;reg_load = 16'd11;reg_addr = 4'd0;
	#9 insload = 16'b0011_0000_0001_0011;load = 1'b1;laddr = 16'd2;reg_load = 16'd10;reg_addr = 4'd1;
	#9 loadreg = 1'b0;load =1'b0;
//#20 $display("z = %b, c_out = %b\n",z1,c_out1);
end
endmodule

//-------------------Instruction Memory Module-------------------//
module insmemory(ins_out,ins_load,l_addr,pc_addr,load,clock);

input  clock,load;
input  [15:0]ins_load;  //16bit instruction
input  [15:0]l_addr;     //load address
input  [15:0]pc_addr;    //PC address
output reg[15:0]ins_out;   //instruction output 16'bit
reg [7:0]mem_file[64:0];   //Instruction fetch registor

//Load
always @(posedge clock&load)
begin
    mem_file[l_addr]=ins_load[15:8];
    mem_file[l_addr+1]=ins_load[7:0];
     
end

//Out
always @(posedge clock)
begin
     ins_out[15:0]={mem_file[pc_addr],mem_file[pc_addr+1]};
end

endmodule
//--------------------------------------------------------------//
	
//---------------Register File Module-----------------------//
module registerfile(A,B,Aaddr,Baddr,Caddr,C,load,clear,clock);
//define I/O ports
input [3:0] Aaddr,Baddr,Caddr;
input [15:0]C;
input load,clear,clock;

output reg [15:0] A,B;

//declare 16 register_file
reg [15:0]reg_file[15:0];
//declare count variable for for loop
integer count;

//clear register files using asynchronous,negative clear signal 
always @(negedge clear)
begin
	for ( count=0; count < 16; count = count + 1)
		begin
			reg_file[count] = 16'd0; 
		end
end

//make register write and read as positive edge triggers 
always @(posedge clock)
begin
	// if load = 1 then load word in C to register address in Caddr
	if(load)
		begin
		reg_file[Caddr]	= C;
		end
end
always @(posedge clock)
begin
		//read registry file in every positive edge
		A = reg_file[Aaddr];
		B = reg_file[Baddr];
	end
endmodule
//------------------------------------------------------------------//

//-------------------Multiplexer Module-------------------//
module MUX(out, i0, i1, i2, i3, s1, s0);
	
	// Port declarations from the I/O diagram
	output [15:0]out;
	input [15:0]i0, i1, i2, i3;
	input s1, s0;
	//store tempary values
	reg [15:0]tempout;
	// Multiplexer output change for an input changes
	always @(s0,s1,i0,i1,i2,i3)
	begin	
	
		case ({s1,s0})
				//if selection 00 select output1
			2'd0 : tempout = i0;
				//if selection 01 select output1
			2'd1 : tempout = i1;
				//if selection 10 select output2
			2'd2 : tempout = i2;
				//if selection 11 select output3
			2'd3 : tempout = i3;
			
			default : $display("Invalid signal");	
		endcase
	

	end	
	
	assign out=tempout;
	
endmodule
//---------------------------------------------------------//

module MUX4bit(out, i0, i1, i2, i3, s1, s0);
	
	// Port declarations from the I/O diagram
	output [3:0]out;
	input [3:0]i0, i1, i2, i3;
	input s1, s0;
	//store tempary values
	reg [3:0]tempout;
	// Multiplexer output change for an input changes
	always @(s0,s1,i0,i1,i2,i3)
	begin	
	
		case ({s1,s0})
				//if selection 00 select output1
			2'd0 : tempout = i0;
				//if selection 01 select output1
			2'd1 : tempout = i1;
				//if selection 10 select output2
			2'd2 : tempout = i2;
				//if selection 11 select output3
			2'd3 : tempout = i3;
			
			default : $display("Invalid signal");	
		endcase
	

	end	
	
	assign out=tempout;
	
endmodule
//---------------------------------------------------------//

//-------------------Sign Extender Module-------------------//
module signextender(out,in);
input [3:0]in;
output reg [15:0] out;

always @(in)
begin
	case(in[3])
		1'd0 : 	out = {12'b0,in};
		
		1'd1 :	out = {12'b1,in};

	endcase	
end

endmodule
//-------------------------------------------------------//

//-------------------ALU Module-------------------//
module alu(z,c_out,lt,eq,gt,overflow,x,y,c_in,c);

//declare inputs & outputs
input c_in;
input [2:0] c;
input [15:0]x,y;

output reg [15:0] z;
output reg c_out,lt,eq,gt,overflow;

always @(c_in,c,x,y)
begin
	case(c)
		3'd0:	z = x & y;
		
		3'd1:	z = x | y;
		
		3'd2:	begin
				{c_out,z} = x + y + c_in ; 	
				overflow = c_out;
			end
				
		3'd3:	z = x - y;

		3'd7:	
			begin
				if(x < y)
					begin
					z = 16'd1;
					end
				else
					begin
						$display("Invalid signal");
					end
			end
		default : $display("Invalid signal");	
	endcase

end
always @(x,y)
begin
	if(x < y)
		begin
			lt = 1;
			gt = 0;
			eq = 0;
		end
	else if(x > y)
		begin
			lt = 0;
			gt = 1;
			eq = 0;
		end
	else if(x == y)
		begin
			lt = 0;
			gt = 0;
			eq = 1;
		end
	else
		begin
			$display("Invalid signal");
		end
end
endmodule 
//----------------------------------------------------------//

//---------------Data Memory Module-----------------------//
module memory(read,addr,write,memread,memwrite,clock);
//define I/O ports
input [15:0] addr,write;
input memread,memwrite,clock;

output reg [15:0] read;

//declare 32 memory_files
reg [15:0]reg_file[32:0];

//make memory write and read as positive edge triggers 
always @(posedge clock)
begin
	// if load = 1 then load word in C to register address in Caddr
	if(memwrite == 1)
		begin
		reg_file[addr]	= write;
		end
	else if(memread == 1)
		begin
		read = reg_file[addr];
		end
end

endmodule
//------------------------------------------------------------------//

//-------------------Program Counter Module-------------------//
module pc(pc_old,pc_new,clock);
input clock;
input [15:0]pc_new;
output reg[15:0]pc_old;

initial
  #26 pc_old=16'd0;

always@(posedge clock)
begin
   pc_old=pc_new; 
  end
endmodule
//---------------------------------------------------------//

//-------------------JUMP Module-------------------//
module jump(out,offset,pc);
//Declare I/O ports
input [11:0] offset;
input [2:0] pc;
output reg [15:0] out;

always @(offset)
begin
	out = {pc,offset,1'b0};
end
endmodule
//-------------------------------------------------//

//-------------------Controller Module-------------------//
module controller(muxinput,inputofand,aluinput,memread,memwrite,regload,opcode,clock);
//Declare input/outputs
input [3:0] opcode;
input clock;

output reg [2:0] muxinput;	//Multiplexers selection input
output reg inputofand,memread,memwrite,regload;	//input of and gate connected M3,memory read & write selections,reg_file load respectively
output reg [2:0] aluinput;	//Operation selection bits for ALU0

//Make controller as positive edge triggered device 
always @(posedge clock)
begin
	case(opcode)
	//OPCODE 0000 : AND INSTRUCTION
	4'd0:	begin
				regload = 1;
				memread = 0;
				memwrite = 0;
				inputofand = 0;
				aluinput = 3'd0;
				muxinput[0] = 0;
				muxinput[1] = 1;
				muxinput[2] = 0;
			end
			
	//OPCODE 0001 : OR INSTRUCTION		
	4'd1:	begin
				regload = 1;
				memread = 0;
				memwrite = 0;
				inputofand = 0;
				aluinput = 3'd1;
				muxinput[0] = 0;
				muxinput[1] = 1;
				muxinput[2] = 0;
			end
	
	//OPCODE 0010 : ADD INSTRUCTION
	4'd2:	begin
				regload = 1;
				memread = 0;
				memwrite = 0;
				inputofand = 0;
				aluinput = 3'd2;
				muxinput[0] = 0;
				muxinput[1] = 1;
				muxinput[2] = 0;
			end
	
	//OPCODE 0110 : SUB INSTRUCTION
	4'd6:	begin
				regload = 1;
				memread = 0;
				memwrite = 0;
				inputofand = 0;
				aluinput = 3'd3;
				muxinput[0] = 0;
				muxinput[1] = 1;
				muxinput[2] = 0;
			end
	
	//OPCODE 0111 : SLT INSTRUCTION
	4'd7:	begin
				regload = 1;
				memread = 0;
				memwrite = 0;
				inputofand = 0;
				aluinput = 3'd7;
				muxinput[0] = 0;
				muxinput[1] = 1;
				muxinput[2] = 0;
			end
	
	//OPCODE 1000 : LW INSTRUCTION
	4'd8:	begin
				regload = 1;
				inputofand = 0;
				aluinput = 3'd2;
				memread = 1;
				memwrite = 0;
				muxinput[0] = 1;
				muxinput[1] = 0;
				muxinput[2] = 0;
			end

	//OPCODE 1010 : SW INSTRUCTION
	4'd10:	begin
				regload = 0;
				inputofand = 0;
				aluinput = 3'd2;
				memread = 0;
				memwrite = 1;
				muxinput[0] = 1;
				muxinput[2] = 0;
			end
			
	//OPCODE 1110 : BNE INSTRUCTION
	4'd14:	begin
				regload = 0;
				inputofand = 1;
				aluinput = 3'd7;
				memread = 0;
				memwrite = 0;
				muxinput[0] = 0;
				muxinput[2] = 0;
			end		
	
	//OPCODE 1111 : JUMP INSTRUCTION
	4'd15:	begin
				regload = 0;
				memread = 0;
				memwrite = 0;
				muxinput[2] = 1;
			end	
	
	endcase
end
endmodule
//---------------------------------------------------------//