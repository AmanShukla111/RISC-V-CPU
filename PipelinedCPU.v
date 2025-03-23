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
`include "HazardDetection.v"
`include "ForwardingUnit.v"

`include "IF_ID_PipelineReg.v"
`include "ID_EX_PipelineReg.v"
`include "EX_MEM_PipelineReg.v"
`include "MEM_WB_PipelineReg.v"

module PipelinedCPU (
    input clk,
    input start
);

    //----------------------------------------
    // Stage 1: IF
    //----------------------------------------
    wire [31:0] pc_IF, pcNext_IF, pcPlus4_IF, instr_IF;

    reg  pcWrite;      // to stall the PC
    wire if_id_write;  // to stall IF/ID pipeline
    wire if_id_flush;  // to flush IF/ID on branch

    // PC register
    reg [31:0] pc_reg;
    always @(posedge clk) begin
        if (!start) begin          
            pc_reg <= 32'b0;
        end else if (pcWrite) begin
            pc_reg <= pcNext_IF;
        end
    end
    assign pc_IF = pc_reg;

    // Instruction Memory
    InstructionMemory m_InstMem(
        .readAddr(pc_IF),
        .inst(instr_IF)
    );

    // pc + 4
    Adder adder_if_pcplus4(
        .a(pc_IF),
        .b(32'd4),
        .sum(pcPlus4_IF)
    );

    //----------------------------------------
    // IF/ID Pipeline Register
    //----------------------------------------
    wire [31:0] pc_ID, instr_ID;
    IF_ID_PipelineReg if_id_reg(
        .clk(clk),
        .rst(start),        // active-high reset now
        .if_id_write(if_id_write),
        .flush(if_id_flush),
        .pc_in(pc_IF),
        .instr_in(instr_IF),
        .pc_out(pc_ID),
        .instr_out(instr_ID)
    );

    //----------------------------------------
    // Stage 2: ID
    //----------------------------------------
    wire [31:0] imm_ID;
    wire [1:0]  ALUOp_ID;
    wire memRead_ID, memWrite_ID, memToReg_ID, regWrite_ID, ALUSrc_ID;
    wire branch_ID;
    reg [31:0] readData1_ID, readData2_ID;

    wire [4:0] rs1_ID = instr_ID[19:15];
    wire [4:0] rs2_ID = instr_ID[24:20];
    wire [4:0] rd_ID  = instr_ID[11:7];

    // Control
    Control m_Control(
        .opcode(instr_ID[6:0]),
        .funct3(instr_ID[14:12]),
        .branch(branch_ID), 
        .memRead(memRead_ID),
        .memtoReg(memToReg_ID),
        .ALUOp(ALUOp_ID),
        .memWrite(memWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .regWrite(regWrite_ID)
    );

    wire [31:0] rawReadData1_ID, rawReadData2_ID;

    Register regFile (
        .clk(clk),
        .rst(start),
        .readReg1_ID(rs1_ID), 
        .readReg2_ID(rs2_ID),
        .readData1_ID(rawReadData1_ID),
        .readData2_ID(rawReadData2_ID),
        .regWrite_WB(regWrite_WB),
        .writeReg_WB(rd_WB),
        .writeData_WB(finalWBData)
    );


    // ImmGen
    ImmGen #(32) m_ImmGen(
        .instruction(instr_ID),
        .imm(imm_ID)
    );

    //----------------------------------------
    // ID/EX Pipeline Register
    //----------------------------------------
    wire [31:0] pc_EX, rdData1_EX, rdData2_EX, imm_EX;
    wire [4:0]  rd_EX, rs1_EX, rs2_EX;
    wire [2:0]  funct3_EX;
    wire        funct7b5_EX;
    wire        memRead_EX, memWrite_EX, memToReg_EX, regWrite_EX, ALUSrc_EX, branch_EX;
    wire [1:0]  ALUOp_EX;

    wire id_ex_write;
    wire id_ex_flush;

    ID_EX_PipelineReg id_ex_reg(
        .clk(clk),
        .rst(start),    // active-high reset
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
        .pc_in(pc_ID),
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

    // If your ID stage has 'instr_ID' as the 32-bit instruction
    reg [3:0] stopCounter = 0;
    reg detectingDeadcode = 0;

    always @(posedge clk) begin
        if (!start) begin
            stopCounter <= 0;
            detectingDeadcode <= 0;
        end else begin
            if (instr_ID == 32'hDEADC0DE && !detectingDeadcode) begin
                detectingDeadcode <= 1;
                stopCounter <= 3;
            end
            else if (detectingDeadcode && stopCounter > 0) begin
                stopCounter <= stopCounter - 1;
                if (stopCounter == 1) begin
                    $display("Reached DEADCODE + drain cycles, stopping sim...");
                    $finish;
                end
            end
        end
    end


    //----------------------------------------
    // Stage 3: EX
    //----------------------------------------
    wire [1:0] forwardA_EX, forwardB_EX;
    wire [31:0] aluResult_MEM;
    wire [31:0] writeData_WB;

    ForwardingUnit fwd_unit(
        .rs1_EX(rs1_EX),
        .rs2_EX(rs2_EX),
        .rd_MEM(rd_MEM),
        .rd_WB(rd_WB),
        .regWrite_MEM(regWrite_MEM),
        .regWrite_WB(regWrite_WB),
        .forwardA(forwardA_EX),
        .forwardB(forwardB_EX)
    );

    // Shift imm for branch offset
    wire [31:0] immShifted_EX;
    ShiftLeftOne sh1(
        .i(imm_EX),
        .o(immShifted_EX)
    );

    // Branch target
    wire [31:0] branchTarget_EX = pc_EX + immShifted_EX;

    // Forwarding MUX logic
    reg [31:0] forwardA_val, forwardB_val;
    always @(*) begin
        case (forwardA_EX)
            2'b00: forwardA_val = rdData1_EX;
            2'b10: forwardA_val = aluResult_MEM;
            2'b01: forwardA_val = writeData_WB;
            default: forwardA_val = rdData1_EX;
        endcase
    end

    always @(*) begin
        case (forwardB_EX)
            2'b00: forwardB_val = rdData2_EX;
            2'b10: forwardB_val = aluResult_MEM;
            2'b01: forwardB_val = writeData_WB;
            default: forwardB_val = rdData2_EX;
        endcase
    end

    // ALUSrc mux
    wire [31:0] aluOperandB_EX = (ALUSrc_EX) ? imm_EX : forwardB_val;

    // ALU Control
    wire [3:0] aluControl_EX;
    ALUCtrl alu_ctrl_ex(
        .ALUOp(ALUOp_EX),
        .funct7(funct7b5_EX),
        .funct3(funct3_EX),
        .ALUCtl(aluControl_EX)
    );

    // ALU
    wire [31:0] aluResult_EX;
    wire        zero_EX;
    ALU alu_ex(
        .ALUCtl(aluControl_EX),
        .A(forwardA_val),
        .B(aluOperandB_EX),
        .ALUOut(aluResult_EX),
        .zero(zero_EX)
    );

    // Branch decision: e.g. for BEQ => if branch_EX && zero_EX
    wire branchTaken_EX = branch_EX && zero_EX;

    //----------------------------------------
    // EX/MEM pipeline
    //----------------------------------------
    wire [31:0] writeData_MEM;
    wire        memRead_MEM, memWrite_MEM, memToReg_MEM, regWrite_MEM;
    wire [4:0]  rd_MEM;

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
    // Stage 4: MEM
    //----------------------------------------
    wire [31:0] memReadData_MEM;
    WrapperMemory wmem(
        .clk(clk),
        .rst(start),
        .memWrite(memWrite_MEM),
        .memRead(memRead_MEM),
        .address(aluResult_MEM),
        .writeData(writeData_MEM),
        .funct3(funct3_EX), // simplified
        .readData(memReadData_MEM)
    );

    //----------------------------------------
    // MEM/WB pipeline
    //----------------------------------------
    wire regWrite_WB, memToReg_WB;
    wire [31:0] aluResult_WB, memReadData_WB;
    wire [4:0]  rd_WB;

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
    // Stage 5: WB
    //----------------------------------------
    wire [31:0] finalWBData;
    Mux2to1 #(32) mux_wb(
        .sel(memToReg_WB),
        .s0(aluResult_WB),
        .s1(memReadData_WB),
        .out(finalWBData)
    );

    //----------------------------------------
    // Next PC Logic: Branch or PC+4
    //----------------------------------------
    assign pcNext_IF = (branchTaken_EX) ? branchTarget_EX : pcPlus4_IF;

    //----------------------------------------
    // HAZARD DETECTION (load-use stalling)
    //----------------------------------------
    wire stallF, stallD, flushE;
    HazardDetection hazard_unit(
        .rs1_ID(rs1_ID),
        .rs2_ID(rs2_ID),
        .rd_EX(rd_EX),
        .memRead_EX(memRead_EX),
        .stallF(stallF),
        .stallD(stallD),
        .flushE(flushE)
    );

    // Stall signals (load-use hazard):
    always @(*) begin
        pcWrite = ~stallF;
    end
    assign if_id_write = ~stallF;

    // ID/EX pipeline stall or flush
    assign id_ex_write = ~stallD;
    assign id_ex_flush = flushE || branchTaken_EX;
    assign if_id_flush = branchTaken_EX;


    always @(*) begin
        // Default: use raw register file outputs
        readData1_ID = rawReadData1_ID;
        readData2_ID = rawReadData2_ID;

        // If the WB stage is writing a register that matches rs1_ID, override
        if (regWrite_WB && (rd_WB != 0) && (rd_WB == rs1_ID)) begin
            readData1_ID = finalWBData;
        end

        // Similarly for rs2
        if (regWrite_WB && (rd_WB != 0) && (rd_WB == rs2_ID)) begin
            readData2_ID = finalWBData;
        end
    end


endmodule
