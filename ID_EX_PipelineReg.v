module ID_EX_PipelineReg(
    input         clk,
    input         rst,
    input         writeEnable,   // for stalling the pipeline
    input         flush,         // for inserting a bubble (NOP) in EX

    //------------- Control Signals In -------------
    input         regWrite_in,
    input         memtoReg_in,
    input         memRead_in,
    input         memWrite_in,
    input  [1:0]  ALUOp_in,
    input         ALUSrc_in,

    //------------- Data In -------------
    input  [31:0] pc_in,
    input  [31:0] readData1_in,
    input  [31:0] readData2_in,
    input  [31:0] imm_in,
    input  [4:0]  rd_in,
    input  [4:0]  rs1_in,        // <--- new
    input  [4:0]  rs2_in,        // <--- new
    input  [2:0]  funct3_in,
    input         funct7b5_in,
    input branch_in,
    output reg branch_out,

    //------------- Control Signals Out -------------
    output reg    regWrite_out,
    output reg    memtoReg_out,
    output reg    memRead_out,
    output reg    memWrite_out,
    output reg [1:0] ALUOp_out,
    output reg    ALUSrc_out,

    //------------- Data Out -------------
    output reg [31:0] pc_out,
    output reg [31:0] readData1_out,
    output reg [31:0] readData2_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rd_out,
    output reg [4:0]  rs1_out,    // <--- new
    output reg [4:0]  rs2_out,    // <--- new
    output reg [2:0]  funct3_out,
    output reg        funct7b5_out
);

always @(posedge clk) begin
    if (!rst) begin
        // On reset, clear everything
        branch_out     <= 0;
        regWrite_out   <= 0;
        memtoReg_out   <= 0;
        memRead_out    <= 0;
        memWrite_out   <= 0;
        ALUOp_out      <= 2'b00;
        ALUSrc_out     <= 0;

        pc_out         <= 32'b0;
        readData1_out  <= 32'b0;
        readData2_out  <= 32'b0;
        imm_out        <= 32'b0;
        rd_out         <= 5'b0;
        rs1_out        <= 5'b0;
        rs2_out        <= 5'b0;
        funct3_out     <= 3'b0;
        funct7b5_out   <= 1'b0;

    end else if (flush) begin
        // Insert a bubble (NOP) in EX stage by clearing control signals
        regWrite_out   <= 0;
        memtoReg_out   <= 0;
        memRead_out    <= 0;
        memWrite_out   <= 0;
        ALUOp_out      <= 2'b00;
        ALUSrc_out     <= 0;
        branch_out     <= 0;

        // Optionally zero out data as well
        pc_out         <= 32'b0;
        readData1_out  <= 32'b0;
        readData2_out  <= 32'b0;
        imm_out        <= 32'b0;
        rd_out         <= 5'b0;
        rs1_out        <= 5'b0;
        rs2_out        <= 5'b0;
        funct3_out     <= 3'b0;
        funct7b5_out   <= 1'b0;

    end else if (writeEnable) begin
        // Normal update
        branch_out     <= branch_in;
        regWrite_out   <= regWrite_in;
        memtoReg_out   <= memtoReg_in;
        memRead_out    <= memRead_in;
        memWrite_out   <= memWrite_in;
        ALUOp_out      <= ALUOp_in;
        ALUSrc_out     <= ALUSrc_in;

        pc_out         <= pc_in;
        readData1_out  <= readData1_in;
        readData2_out  <= readData2_in;
        imm_out        <= imm_in;
        rd_out         <= rd_in;
        rs1_out        <= rs1_in;    // <--- new
        rs2_out        <= rs2_in;    // <--- new
        funct3_out     <= funct3_in;
        funct7b5_out   <= funct7b5_in;
    end
    // else: hold old values if writeEnable=0 (stalling)
end

endmodule
