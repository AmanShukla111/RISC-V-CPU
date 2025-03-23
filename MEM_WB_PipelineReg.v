module MEM_WB_PipelineReg(
    input         clk,
    input         rst,
    // Control signals
    input         regWrite_in,
    input         memToReg_in,
    // Data
    input  [31:0] aluResult_in,
    input  [31:0] memReadData_in,
    input  [4:0]  rd_in,
    output reg    regWrite_out,
    output reg    memToReg_out,
    output reg [31:0] aluResult_out,
    output reg [31:0] memReadData_out,
    output reg [4:0]  rd_out
);

always @(posedge clk) begin
    if (!rst) begin
        regWrite_out     <= 0;
        memToReg_out     <= 0;
        aluResult_out    <= 32'b0;
        memReadData_out  <= 32'b0;
        rd_out           <= 5'b0;
    end else begin
        regWrite_out     <= regWrite_in;
        memToReg_out     <= memToReg_in;
        aluResult_out    <= aluResult_in;
        memReadData_out  <= memReadData_in;
        rd_out           <= rd_in;
    end
end

endmodule
