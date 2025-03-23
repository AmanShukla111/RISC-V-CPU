//------------------//
//   StageEX.v
//------------------//
`include "ForwardingUnit.v"
`include "ShiftLeftOne.v"
`include "ALUCtrl.v"
`include "ALU.v"

module StageEX(
    // from ID/EX pipeline
    input  [31:0] pc_EX,
    input  [31:0] readData1_EX,
    input  [31:0] readData2_EX,
    input  [31:0] imm_EX,
    input  [4:0]  rs1_EX,
    input  [4:0]  rs2_EX,
    input  [4:0]  rd_EX,
    input  [2:0]  funct3_EX,
    input         funct7b5_EX,
    input  [1:0]  ALUOp_EX,
    input         memRead_EX,
    input         memWrite_EX,
    input         memToReg_EX,
    input         regWrite_EX,
    input         ALUSrc_EX,
    input         branch_EX,

    // forwarding inputs
    input  [31:0] aluResult_MEM,
    input  [31:0] writeData_WB,
    input         regWrite_MEM,
    input         regWrite_WB,
    input  [4:0]  rd_MEM,
    input  [4:0]  rd_WB,

    // outputs
    output [31:0] aluResult_out,
    output        zero_out,
    output        branchTaken_out
);

    // Forwarding
    wire [1:0] forwardA, forwardB;
    ForwardingUnit fwd_unit(
        .rs1_EX(rs1_EX),
        .rs2_EX(rs2_EX),
        .rd_MEM(rd_MEM),
        .rd_WB(rd_WB),
        .regWrite_MEM(regWrite_MEM),
        .regWrite_WB(regWrite_WB),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    reg [31:0] forwardA_val, forwardB_val;
    always @(*) begin
        case (forwardA)
            2'b00: forwardA_val = readData1_EX;
            2'b10: forwardA_val = aluResult_MEM;
            2'b01: forwardA_val = writeData_WB;
            default: forwardA_val = readData1_EX;
        endcase
    end

    always @(*) begin
        case (forwardB)
            2'b00: forwardB_val = readData2_EX;
            2'b10: forwardB_val = aluResult_MEM;
            2'b01: forwardB_val = writeData_WB;
            default: forwardB_val = readData2_EX;
        endcase
    end

    // ALUSrc
    wire [31:0] aluOperandB = (ALUSrc_EX) ? imm_EX : forwardB_val;

    // ALU Control
    wire [3:0] aluControl;
    ALUCtrl alu_ctrl_ex(
        .ALUOp(ALUOp_EX),
        .funct7(funct7b5_EX),
        .funct3(funct3_EX),
        .ALUCtl(aluControl)
    );

    // ALU
    wire [31:0] aluResult;
    wire        zero;
    ALU alu_ex(
        .ALUCtl(aluControl),
        .A(forwardA_val),
        .B(aluOperandB),
        .ALUOut(aluResult),
        .zero(zero)
    );

    // Branch decision
    wire branchTaken = branch_EX && (zero == 1'b1);

    assign aluResult_out     = aluResult;
    assign zero_out          = zero;
    assign branchTaken_out   = branchTaken;

endmodule
