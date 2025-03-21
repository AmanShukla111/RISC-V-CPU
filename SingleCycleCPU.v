`include "PC.v"
`include "Adder.v"
`include "InstructionMemory.v"
`include "Control.v"
`include "Register.v"
`include "ImmGen.v"
`include "ShiftLeftOne.v"
`include "Mux2to1.v"
`include "ALUCtrl.v"
`include "ALU.v"
`include "DataMemory.v"

module SingleCycleCPU (
    input clk,
    input start
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

// Wire declarations
wire [31:0] pc_current, pc_next, pc_plus4; // addresses can remain unsigned
wire signed [31:0] branch_target;
wire [31:0] instruction;
wire [31:0] read_data1, read_data2; // from Register module (could be cast to signed later)
wire [31:0] write_data;
wire signed [31:0] imm_gen_out, imm_gen_out_shifted;
wire branch_inst = (instruction[6:0] == 7'b1100011);
wire signed [31:0] effective_imm = branch_inst ? imm_gen_out:(is_jal ? imm_gen_out : imm_gen_out_shifted);
wire signed [31:0] alu_result;
wire signed [31:0] mem_read_data; // memory data can be considered signed if used arithmetically
wire signed [31:0] alu_operand2;
wire [3:0] alu_control;
wire [1:0] alu_op;
wire branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write;
wire zero_flag;
wire signed [31:0] alu_or_jal;

wire is_jal = (instruction[6:0] == 7'b1101111);
wire jump_sel = (branch & zero_flag) | is_jal;


// PC module
PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(pc_next),
    .pc_o(pc_current)
);

// Adder for PC+4
Adder m_Adder_1(
    .a(pc_current),
    .b(32'd4),
    .sum(pc_plus4)
);

// Instruction Memory
InstructionMemory m_InstMem(
    .readAddr(pc_current),
    .inst(instruction)
);

// Control Unit
Control m_Control(
    .opcode(instruction[6:0]),
    .funct3(instruction[14:12]),
    .branch(branch),
    .memRead(mem_read),
    .memtoReg(mem_to_reg),
    .ALUOp(alu_op),
    .memWrite(mem_write),
    .ALUSrc(alu_src),
    .regWrite(reg_write)
);

// Register File
Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(reg_write),
    .readReg1(instruction[19:15]),
    .readReg2(instruction[24:20]),
    .writeReg(instruction[11:7]),
    .writeData(write_data),
    .readData1(read_data1),
    .readData2(read_data2)
);

// Immediate Generator
ImmGen #(.Width(32)) m_ImmGen(
    .inst(instruction),
    .imm(imm_gen_out)
);

// Shift Left One (for branch target calculation)
ShiftLeftOne m_ShiftLeftOne(
    .i(imm_gen_out),
    .o(imm_gen_out_shifted)
);

Adder m_Adder_2(
    .a(pc_current),
    .b(effective_imm),
    .sum(branch_target)
);


// Mux for PC source selection
Mux2to1 #(.size(32)) m_Mux_PC(
    .sel(jump_sel),
    .s0(pc_plus4),
    .s1(branch_target),
    .out(pc_next)
);

// Mux for ALU operand selection
Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(alu_src),
    .s0(read_data2),
    .s1(imm_gen_out),
    .out(alu_operand2)
);

// ALU Control
ALUCtrl m_ALUCtrl(
    .ALUOp(alu_op),
    .funct7(instruction[30]),
    .funct3(instruction[14:12]),
    .ALUCtl(alu_control)
);

// ALU
ALU m_ALU(
    .ALUCtl(alu_control),
    .A(read_data1),
    .B(alu_operand2),
    .ALUOut(alu_result),
    .zero(zero_flag)
);

// Data Memory
DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(mem_write),
    .memRead(mem_read),
    .address(alu_result),
    .writeData(read_data2),
    .readData(mem_read_data)
);

// Mux for Write Data selection
Mux2to1 #(.size(32)) m_Mux_WriteData(
    .sel(mem_to_reg),
    .s0(alu_or_jal),
    .s1(mem_read_data),
    .out(write_data)
);

Mux2to1 #(.size(32)) mux_jal(
    .sel(is_jal),
    .s0(alu_result),   // normal ALU result
    .s1(pc_plus4),     // JAL: return address
    .out(alu_or_jal)
);

endmodule
