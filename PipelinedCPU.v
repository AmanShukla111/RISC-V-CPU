//------------------//
// PipelinedCPU.v
//------------------//
`include "StageIF.v"
`include "StageID.v"
`include "StageEX.v"
`include "StageMEM.v"
`include "StageWB.v"

// pipeline registers
`include "IF_ID_PipelineReg.v"
`include "ID_EX_PipelineReg.v"
`include "EX_MEM_PipelineReg.v"
`include "MEM_WB_PipelineReg.v"

// hazard, forwarding, etc.
`include "HazardDetection.v"

module PipelinedCPU (
    input clk,
    input start
);

    //----------------------------------------
    // StageIF
    //----------------------------------------
    wire [31:0] pc_IF, pcPlus4_IF, instr_IF;
    reg pcWrite;
    wire [31:0] pcNext_IF;

    StageIF stageIF(
        .clk(clk),
        .run(start),
        .pcWrite(pcWrite),
        .pcNext_IF(pcNext_IF),
        .pc_IF(pc_IF),
        .pcPlus4_IF(pcPlus4_IF),
        .instr_IF(instr_IF)
    );

    //-----------
    // IF/ID pipeline
    //-----------
    wire [31:0] pc_ID, instr_ID;
    wire if_id_write, if_id_flush;

    IF_ID_PipelineReg if_id_reg(
        .clk(clk),
        .rst(start),
        .if_id_write(if_id_write),
        .flush(if_id_flush),
        .pc_in(pc_IF),
        .instr_in(instr_IF),
        .pc_out(pc_ID),
        .instr_out(instr_ID)
    );

    //----------------------------------------
    // StageID
    //----------------------------------------
    wire [31:0] imm_ID, readData1_ID, readData2_ID, pc_out_ID;
    wire [4:0]  rs1_ID, rs2_ID, rd_ID;
    wire [1:0]  ALUOp_ID;
    wire        memRead_ID, memWrite_ID, memToReg_ID, regWrite_ID, ALUSrc_ID, branch_ID;
    wire        detectDeadcode_ID;

    StageID stageID(
        .clk(clk),
        .run(start),
        .pc_ID(pc_ID),
        .instr_ID(instr_ID),

        // from WB
        .regWrite_WB(regWrite_WB),
        .rd_WB(rd_WB),
        .finalWBData(finalWBData),

        // to ID/EX
        .pc_out_ID(pc_out_ID),
        .imm_ID(imm_ID),
        .readData1_ID(readData1_ID),
        .readData2_ID(readData2_ID),
        .rs1_ID(rs1_ID),
        .rs2_ID(rs2_ID),
        .rd_ID(rd_ID),

        // control out
        .branch_ID(branch_ID),
        .memRead_ID(memRead_ID),
        .memWrite_ID(memWrite_ID),
        .memToReg_ID(memToReg_ID),
        .regWrite_ID(regWrite_ID),
        .ALUSrc_ID(ALUSrc_ID),
        .ALUOp_ID(ALUOp_ID),

        .detectDeadcode_ID(detectDeadcode_ID)
    );

    //-----------
    // ID/EX pipeline
    //-----------
    wire [31:0] pc_EX, rdData1_EX, rdData2_EX, imm_EX;
    wire [4:0]  rs1_EX, rs2_EX, rd_EX;
    wire [2:0]  funct3_EX;
    wire        funct7b5_EX;
    wire [1:0]  ALUOp_EX;
    wire        memRead_EX, memWrite_EX, memToReg_EX, regWrite_EX, ALUSrc_EX, branch_EX;
    wire id_ex_write, id_ex_flush;

    ID_EX_PipelineReg id_ex_reg(
        .clk(clk),
        .rst(start),
        .writeEnable(id_ex_write),
        .flush(id_ex_flush),

        // control in
        .regWrite_in(regWrite_ID),
        .branch_in(branch_ID),
        .memtoReg_in(memToReg_ID),
        .memRead_in(memRead_ID),
        .memWrite_in(memWrite_ID),
        .ALUOp_in(ALUOp_ID),
        .ALUSrc_in(ALUSrc_ID),

        // data in
        .pc_in(pc_out_ID),
        .readData1_in(readData1_ID),
        .readData2_in(readData2_ID),
        .imm_in(imm_ID),
        .rd_in(rd_ID),
        .rs1_in(rs1_ID),
        .rs2_in(rs2_ID),
        .funct3_in(instr_ID[14:12]),
        .funct7b5_in(instr_ID[30]),

        // control out
        .regWrite_out(regWrite_EX),
        .branch_out(branch_EX),
        .memtoReg_out(memToReg_EX),
        .memRead_out(memRead_EX),
        .memWrite_out(memWrite_EX),
        .ALUOp_out(ALUOp_EX),
        .ALUSrc_out(ALUSrc_EX),

        // data out
        .pc_out(pc_EX),
        .readData1_out(rdData1_EX),
        .readData2_out(rdData2_EX),
        .imm_out(imm_EX),
        .rd_out(rd_EX),
        .rs1_out(rs1_EX),
        .rs2_out(rs2_EX),
        .funct3_out(funct3_EX),
        .funct7b5_out(funct7b5_EX)
    );

    //----------------------------------------
    // StageEX
    //----------------------------------------
    wire [31:0] aluResult_EX, aluResult_MEM;
    wire        zero_EX;
    wire        branchTaken_EX;

    StageEX stageEX(
        .pc_EX(pc_EX),
        .readData1_EX(rdData1_EX),
        .readData2_EX(rdData2_EX),
        .imm_EX(imm_EX),
        .rs1_EX(rs1_EX),
        .rs2_EX(rs2_EX),
        .rd_EX(rd_EX),
        .funct3_EX(funct3_EX),
        .funct7b5_EX(funct7b5_EX),
        .ALUOp_EX(ALUOp_EX),
        .memRead_EX(memRead_EX),
        .memWrite_EX(memWrite_EX),
        .memToReg_EX(memToReg_EX),
        .regWrite_EX(regWrite_EX),
        .ALUSrc_EX(ALUSrc_EX),
        .branch_EX(branch_EX),

        // forwarding
        .aluResult_MEM(aluResult_MEM),
        .writeData_WB(finalWBData),
        .regWrite_MEM(regWrite_MEM),
        .regWrite_WB(regWrite_WB),
        .rd_MEM(rd_MEM),
        .rd_WB(rd_WB),

        // outputs
        .aluResult_out(aluResult_EX),
        .zero_out(zero_EX),
        .branchTaken_out(branchTaken_EX)
    );

    //-----------
    // EX/MEM pipeline
    //-----------
    wire [31:0] writeData_MEM;
    wire memRead_MEM, memWrite_MEM, memToReg_MEM, regWrite_MEM;
    wire [4:0] rd_MEM;

    EX_MEM_PipelineReg ex_mem_reg(
        .clk(clk),
        .rst(start),
        .regWrite_in(regWrite_EX),
        .memToReg_in(memToReg_EX),
        .memRead_in(memRead_EX),
        .memWrite_in(memWrite_EX),

        .aluResult_in(aluResult_EX),
        .writeData_in(rdData2_EX),
        .rd_in(rd_EX),

        .regWrite_out(regWrite_MEM),
        .memToReg_out(memToReg_MEM),
        .memRead_out(memRead_MEM),
        .memWrite_out(memWrite_MEM),

        .aluResult_out(aluResult_MEM),
        .writeData_out(writeData_MEM),
        .rd_out(rd_MEM)
    );

    //----------------------------------------
    // StageMEM
    //----------------------------------------
    wire [31:0] memReadData_MEM;

    StageMEM stageMEM(
        .clk(clk),
        .run(start),
        .memWrite_MEM(memWrite_MEM),
        .memRead_MEM(memRead_MEM),
        .aluResult_MEM(aluResult_MEM),
        .writeData_MEM(writeData_MEM),
        .funct3_EX(funct3_EX),
        .memReadData_out(memReadData_MEM)
    );

    //-----------
    // MEM/WB pipeline
    //-----------
    wire [31:0] aluResult_WB, memReadData_WB;
    wire memToReg_WB;
    wire regWrite_WB;
    wire [4:0] rd_WB;

    MEM_WB_PipelineReg mem_wb_reg(
        .clk(clk),
        .rst(start),
        .regWrite_in(regWrite_MEM),
        .memToReg_in(memToReg_MEM),

        .aluResult_in(aluResult_MEM),
        .memReadData_in(memReadData_MEM),
        .rd_in(rd_MEM),

        .regWrite_out(regWrite_WB),
        .memToReg_out(memToReg_WB),
        .aluResult_out(aluResult_WB),
        .memReadData_out(memReadData_WB),
        .rd_out(rd_WB)
    );

    //----------------------------------------
    // StageWB
    //----------------------------------------
    wire [31:0] finalWBData;
    StageWB stageWB(
        .memToReg_WB(memToReg_WB),
        .aluResult_WB(aluResult_WB),
        .memReadData_WB(memReadData_WB),
        .finalWBData(finalWBData)
    );

    //----------------------------------------
    // Next PC Logic
    //----------------------------------------
    assign pcNext_IF = branchTaken_EX ? (pc_EX + imm_EX) : pcPlus4_IF;

    //----------------------------------------
    // Hazard Detection
    //----------------------------------------
    wire stallF, stallD, flushE;
    HazardDetection hazard_unit(
        .rs1_ID(rs1_ID),
        .rs2_ID(rs2_ID),
        .rd_EX(rd_EX),
        .memRead_EX(memRead_EX),
        .rd_WB(rd_WB),
        .regWrite_WB(regWrite_WB),
        .isStore_ID(isStore_ID),
        .stallF(stallF),
        .stallD(stallD),
        .flushE(flushE)
    );


    //-----------
    // Stall/Flush logic
    //-----------
    always @(*) begin
        pcWrite = ~stallF;
    end
    assign if_id_write = ~stallF;
    assign id_ex_write = ~stallD;
    assign id_ex_flush = flushE || branchTaken_EX;
    assign if_id_flush = branchTaken_EX;

endmodule