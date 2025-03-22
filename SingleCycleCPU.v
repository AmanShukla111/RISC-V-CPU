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
`include "WrapperMemory.v"

module SingleCycleCPU (
    input clk,
    input start
);

    // When 'start' is 0, CPU should reset
    // When 'start' is 1, CPU runs

    //-------------------------------------------------------------------------
    //  WIRE DECLARATIONS
    //-------------------------------------------------------------------------
    wire [31:0] pc_current, pc_next, pc_plus4;
    wire [31:0] instruction;
    wire [31:0] read_data1, read_data2;
    wire [31:0] write_data;
    wire [31:0] imm_gen_out;
    wire [31:0] imm_gen_out_shifted;
    wire [31:0] branch_target;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;   // from WrapperMemory
    wire [31:0] alu_operand2;
    wire [3:0]  alu_control;
    wire [1:0]  alu_op;
    wire        branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    wire        zero_flag;
    wire [31:0] alu_or_jal;

    // For jump logic
    wire is_jal = (instruction[6:0] == 7'b1101111);
    // If branch is taken (BEQ) or if JAL, we select the branch/jump target
    wire jump_sel = (branch & zero_flag) | is_jal;


    //-------------------------------------------------------------------------
    //  PC REGISTER
    //-------------------------------------------------------------------------
    PC m_PC(
        .clk(clk),
        .rst(start),       // active-low reset (invert 'start' if your PC expects rst=0 => reset)
        .pc_i(pc_next),
        .pc_o(pc_current)
    );

    //-------------------------------------------------------------------------
    //  FETCH: Instruction Memory
    //-------------------------------------------------------------------------
    InstructionMemory m_InstMem(
        .readAddr(pc_current),
        .inst(instruction)
    );

    //-------------------------------------------------------------------------
    //  CONTROL UNIT
    //-------------------------------------------------------------------------
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

    //-------------------------------------------------------------------------
    //  REGISTER FILE
    //-------------------------------------------------------------------------
    Register m_Register(
        .clk(clk),
        .rst(start),           // same reset logic as PC
        .regWrite(reg_write),
        .readReg1(instruction[19:15]),
        .readReg2(instruction[24:20]),
        .writeReg(instruction[11:7]),
        .writeData(write_data),
        .readData1(read_data1),
        .readData2(read_data2)
    );

    //-------------------------------------------------------------------------
    //  IMMEDIATE GENERATOR
    //-------------------------------------------------------------------------
    ImmGen #(.Width(32)) m_ImmGen(
        .instruction(instruction),
        .imm(imm_gen_out)
    );

    //-------------------------------------------------------------------------
    //  BRANCH ADDRESS CALC (Shift, Add)
    //-------------------------------------------------------------------------
    ShiftLeftOne m_ShiftLeftOne(
        .i(imm_gen_out),
        .o(imm_gen_out_shifted)
    );

    // For branch instructions, we typically shift imm by 1. 
    // For JAL, we might skip shifting or do a separate path, 
    // but let's keep your approach consistent:
    wire is_branch_type = (instruction[6:0] == 7'b1100011);
    wire [31:0] effective_imm = is_branch_type ? imm_gen_out_shifted : imm_gen_out;

    Adder m_Adder_Branch(
        .a(pc_current),
        .b(effective_imm),
        .sum(branch_target)
    );

    //-------------------------------------------------------------------------
    //  PC + 4
    //-------------------------------------------------------------------------
    Adder m_Adder_NextPC(
        .a(pc_current),
        .b(32'd4),
        .sum(pc_plus4)
    );

    //-------------------------------------------------------------------------
    //  SELECT PC NEXT
    //-------------------------------------------------------------------------
    Mux2to1 #(.size(32)) m_Mux_PC(
        .sel(jump_sel),
        .s0(pc_plus4),
        .s1(branch_target),
        .out(pc_next)
    );

    //-------------------------------------------------------------------------
    //  ALU OPERAND2: Register or Immediate
    //-------------------------------------------------------------------------
    Mux2to1 #(.size(32)) m_Mux_ALU(
        .sel(alu_src),
        .s0(read_data2),
        .s1(imm_gen_out),   // immediate
        .out(alu_operand2)
    );

    //-------------------------------------------------------------------------
    //  ALU CONTROL
    //-------------------------------------------------------------------------
    ALUCtrl m_ALUCtrl(
        .ALUOp(alu_op),
        .funct7(instruction[30]),   // 1-bit version
        .funct3(instruction[14:12]),
        .ALUCtl(alu_control)
    );

    //-------------------------------------------------------------------------
    //  ALU
    //-------------------------------------------------------------------------
    ALU m_ALU(
        .ALUCtl(alu_control),
        .A(read_data1),
        .B(alu_operand2),
        .ALUOut(alu_result),
        .zero(zero_flag)
    );

    //-------------------------------------------------------------------------
    //  WRAPPERMEMORY for Loads/Stores
    //-------------------------------------------------------------------------
    // Replaces direct DataMemory usage
    WrapperMemory m_WrapperMem(
        .clk(clk),
        .rst(start),
        .memWrite(mem_write),
        .memRead(mem_read),
        .address(alu_result),
        .writeData(read_data2),
        .funct3(instruction[14:12]),   // needed for LB/LH/LBU/LHU, SB/SH
        .readData(mem_read_data)
    );

    //-------------------------------------------------------------------------
    //  JAL / ALU Writeback Mux
    //-------------------------------------------------------------------------
    // If instruction is JAL, we store PC+4 in rd.
    // Otherwise, we store ALU result.
    Mux2to1 #(.size(32)) mux_jal(
        .sel(is_jal),
        .s0(alu_result),
        .s1(pc_plus4),
        .out(alu_or_jal)
    );

    //-------------------------------------------------------------------------
    //  FINAL WRITE DATA SELECT
    //-------------------------------------------------------------------------
    // If mem_to_reg=1, we write memory data; else ALU/JAL result
    Mux2to1 #(.size(32)) m_Mux_WriteData(
        .sel(mem_to_reg),
        .s0(alu_or_jal),
        .s1(mem_read_data),
        .out(write_data)
    );

endmodule
