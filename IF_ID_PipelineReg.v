module IF_ID_PipelineReg(
    input clk,
    input rst,
    input if_id_write,
    input flush,   // new
    input [31:0] pc_in,
    input [31:0] instr_in,
    output reg [31:0] pc_out,
    output reg [31:0] instr_out
);

always @(posedge clk) begin
    if(!rst) begin
        pc_out    <= 32'b0;
        instr_out <= 32'b0;
    end else if(flush) begin
        pc_out    <= 32'b0;
        instr_out <= 32'b0; // bubble
    end else if(if_id_write) begin
        pc_out    <= pc_in;
        instr_out <= instr_in;
    end
    // else hold
end

endmodule
