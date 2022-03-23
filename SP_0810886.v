module SP(
	// INPUT SIGNAL
	clk,
	rst_n,
	in_valid,
	inst,
	mem_dout,
	// OUTPUT SIGNAL
	out_valid,
	inst_addr,
	mem_wen,
	mem_addr,
	mem_din
);



//------------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//------------------------------------------------------------------------

input                    clk, rst_n, in_valid;
input             [31:0] inst;
input  signed     [31:0] mem_dout;
output reg               out_valid;
output reg        [31:0] inst_addr;
output reg               mem_wen;
output reg        [11:0] mem_addr;
output reg signed [31:0] mem_din;

//------------------------------------------------------------------------
//   DECLARATION
//------------------------------------------------------------------------

// FSM
localparam S_IDLE = 'd0;
localparam S_EXE = 'd1;
localparam S_MEM = 'd2;
localparam S_OUT = 'd3;
reg[1:0] current_state, next_state;
reg exedone, memdone;

// Instruction field
reg [5:0] opcode;
reg [4:0] rs;
reg [4:0] rt;
reg [4:0] rd;
reg [4:0] shamt;
reg [5:0] funct;
reg [15:0] imme;

// Extensions
reg signed [31:0] se_imme;
reg signed [31:0] ze_imme;

// ALU result
reg signed [31:0] alu_result;

// Loop for reset
integer i;


// REGISTER FILE, DO NOT EDIT THE NAME.
reg	 signed     [31:0] r      [0:31]; 



//------------------------------------------------------------------------
//   DESIGN
//------------------------------------------------------------------------

always @(posedge clk, negedge rst_n) begin
	// reset signal == 0
	if (!rst_n) begin
		current_state <= S_IDLE;
		// Output siganl reset to 0
		out_valid <= 0;
		mem_wen <= 1;
		mem_addr <= 0;
		mem_din <= 0;
		inst_addr <= 0;
		// Register file reset
		for (i=0 ; i<32 ; i=i+1) begin
			r[i] <= 0;
		end
		// ALU result reset
		alu_result <= 0;
		// Immediate reset
		se_imme <= 0;
		ze_imme <= 0;
		// Instruction field reset
		rs <= 0;
		rt <= 0;
		rd <= 0;
		opcode <= 0;
		shamt <= 0;
		funct <= 0;
		// Status done reset
		exedone <= 0;
		memdone <= 0;

	// reset signal == 1
	end
	else begin
		current_state <= next_state;
		case (current_state)
			S_IDLE :begin
				// Output signal set to default
				out_valid <= 0;
				mem_wen <= 1;
				mem_din <= 0;
				mem_addr <= 0;
				// set done to 0
				exedone <= 0;
				memdone <= 0;
				if (in_valid == 1)  begin
					opcode <= inst[31:26]; // 6 bit
					rs <= inst[25:21]; // 5 bit
					rt <= inst[20:16]; // 5 bit
					rd <= inst[15:11]; // 5 bit
					shamt <= inst[10:6];  // 5 bit
					funct <= inst[5:0];   // 6 bit
					// immediate
					imme <= inst[15:0];
					ze_imme <= {{16{0}}, inst[15:0]};
					se_imme <= {{16{inst[15]}}, inst[15:0]};
				end
			end
			// S_REG : begin
				
			// end
			S_EXE : begin
				if (!exedone) begin
					if (!opcode) begin // R-type
						r[rd] <= alu_result;
						inst_addr <= inst_addr + 4;
					end
					else begin // I-type
						case (opcode)
							'h01 : begin // andi
								r[rt] <= alu_result;
								inst_addr <= inst_addr + 4;
							end 
							'h02 : begin // ori
								r[rt] <= alu_result;
								inst_addr <= inst_addr + 4;
							end
							'h03 : begin // addi
								r[rt] <= alu_result;
								inst_addr <= inst_addr + 4;
							end
							'h04 : begin // subi
								r[rt] <= alu_result;
								inst_addr <= inst_addr + 4;
							end
							'h05 : begin // lw
								inst_addr <= inst_addr + 4;
								mem_wen <= 1;
								mem_addr <= alu_result;
							end
							'h06 : begin // sw
								inst_addr <= inst_addr + 4;
								mem_wen <= 0;
								mem_addr <= alu_result;
							end
							'h07 : begin // beg
								if (alu_result) begin
									inst_addr <= inst_addr + 4 + (se_imme << 2);
								end
								else inst_addr <= inst_addr + 4;
							end
							'h08 : begin // bne
								if (alu_result) begin
									inst_addr <= inst_addr + 4 + (se_imme << 2);
								end
								else inst_addr <= inst_addr + 4;
							end
						endcase
					end
				end
				exedone <= 1;
			end
			S_MEM : begin
				case (opcode)
					'h05 : r[rt] <= mem_dout;
					'h06 : mem_din <= r[rt];
				endcase
				memdone <= 1;
			end

			S_OUT : begin
				out_valid <= 1;
			end
			default : begin
				out_valid <= 0;
				memdone <= 0;
				exedone <= 0;
				mem_wen <= 0;
				mem_din <= 0;
				mem_addr <= 0;
			end
		endcase
	end
end

// FSM
always @(*) begin
	case (current_state)
		S_IDLE : if (in_valid) next_state = S_EXE;
				 else 		   next_state = S_IDLE;
		S_EXE  : if (exedone)  next_state = S_MEM;
				 else 		   next_state = S_EXE;
		S_MEM  : if (memdone)  next_state = S_OUT;
				 else 		   next_state = S_MEM;				 
		S_OUT  : 			   next_state = S_IDLE;
		default: next_state = S_IDLE;
	endcase
end

// ALU
always @(*) begin
	if (!opcode) // R-type
		case (funct)
			0: alu_result = r[rs] & r[rt];		// and
			1: alu_result = r[rs] | r[rt];		// or
			2: alu_result = r[rs] + r[rt];		// add
			3: alu_result = r[rs] - r[rt];		// sub
			4: alu_result = (r[rs] < r[rt]);	// slt
			5: alu_result = r[rs] << shamt;		// sll
			default : alu_result = alu_result;
		endcase
	else begin // I-type
		case (opcode)
			'h01 : alu_result = r[rs] & ze_imme;	// andi
			'h02 : alu_result = r[rs] | ze_imme;	// ori
			'h03 : alu_result = r[rs] + se_imme;	// addi
			'h04 : alu_result = r[rs] - se_imme;	// subi
			'h05 : alu_result = r[rs] + se_imme;	// lw, return mem addr
			'h06 : alu_result = r[rs] + se_imme;	// sw, return mem addr
			'h07 : alu_result = (r[rs] == r[rt]);	// beg
			'h08 : alu_result = (r[rs] != r[rt]);	// bne
			default: alu_result = alu_result;
		endcase
	end
end

endmodule