//------------------//
//   StageID.v
//------------------//
`include "Control.v"
`include "Register.v"
`include "ImmGen.v"

module StageID(
    input         clk,
    input         run,             // 1 => run, 0 => reset
    // from IF/ID pipeline
    input  [31:0] pc_ID,
    input  [31:0] instr_ID,

    // from WB stage (for reg writes)
    input         regWrite_WB,
    input  [4:0]  rd_WB,
    input  [31:0] finalWBData,

    // Outputs to ID/EX pipeline
    output [31:0] pc_out_ID,
    output [31:0] imm_ID,
    output [31:0] readData1_ID,
    output [31:0] readData2_ID,
    output [4:0]  rs1_ID,
    output [4:0]  rs2_ID,
    output [4:0]  rd_ID,
    output       isStore_ID,

    // Control signals out
    output        branch_ID,
    output        memRead_ID,
    output        memWrite_ID,
    output        memToReg_ID,
    output        regWrite_ID,
    output        ALUSrc_ID,
    output [1:0]  ALUOp_ID,

    // For optional deadcode detection
    output        detectDeadcode_ID
);

    // Break down instruction fields
    assign rs1_ID = instr_ID[19:15];
    assign rs2_ID = instr_ID[24:20];
    assign rd_ID  = instr_ID[11:7];
    assign isStore_ID = (memWrite_ID == 1); 


    wire [2:0] funct3_ID = instr_ID[14:12];
    wire [6:0] opcode_ID  = instr_ID[6:0];

    // Control signals
    Control ctrl(
        .opcode(opcode_ID),
        .funct3(funct3_ID),
        .branch(branch_ID),
        .memRead(memRead_ID),
        .memtoReg(memToReg_ID),
        .ALUOp(ALUOp_ID),
        .memWrite(memWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .regWrite(regWrite_ID)
    );

    // Single unified register file
    wire [31:0] rawReadData1, rawReadData2;
    Register regFile(
        .clk(clk),
        .rst(run), // run=0 => reset
        // read ports
        .readReg1_ID(rs1_ID),
        .readReg2_ID(rs2_ID),
        .readData1_ID(rawReadData1),
        .readData2_ID(rawReadData2),
        // write port (from WB)
        .regWrite_WB(regWrite_WB),
        .writeReg_WB(rd_WB),
        .writeData_WB(finalWBData)
    );

    // Simple WB->ID bypass
    reg [31:0] rData1_ID, rData2_ID;
    always @(*) begin
        rData1_ID = rawReadData1;
        rData2_ID = rawReadData2;
        if (regWrite_WB && rd_WB != 0 && rd_WB == rs1_ID)
            rData1_ID = finalWBData;
        if (regWrite_WB && rd_WB != 0 && rd_WB == rs2_ID)
            rData2_ID = finalWBData;
    end

    assign readData1_ID = rData1_ID;
    assign readData2_ID = rData2_ID;

    // Immediate generation
    ImmGen #(32) immgen(
        .instruction(instr_ID),
        .imm(imm_ID)
    );

    // Deadcode detection
    reg [3:0] stopCounter = 0;
    reg detectingDeadcode = 0;
    always @(posedge clk) begin
        if (!run) begin
            stopCounter <= 0;
            detectingDeadcode <= 0;
        end else begin
            if (instr_ID == 32'hDEADC0DE && !detectingDeadcode) begin
                detectingDeadcode <= 1;
                stopCounter <= 3;
            end else if (detectingDeadcode && stopCounter > 0) begin
                stopCounter <= stopCounter - 1;
                if (stopCounter == 1) begin
                    $display("Reached DEADCODE + drain cycles, stopping sim...");
                    $finish;
                end
            end
        end
    end
    assign detectDeadcode_ID = detectingDeadcode;

    // pass PC forward
    assign pc_out_ID = pc_ID;

endmodule
