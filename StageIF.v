//------------------//
//   StageIF.v
//------------------//
`include "InstructionMemory.v"
`include "Adder.v"

module StageIF(
    input         clk,
    input         run,         // 1 => run, 0 => reset
    input         pcWrite,     // stall or not
    input  [31:0] pcNext_IF,
    output [31:0] pc_IF,
    output [31:0] pcPlus4_IF,
    output [31:0] instr_IF
);

    // PC register
    reg [31:0] pc_reg;
    always @(posedge clk) begin
        if (!run) begin
            pc_reg <= 32'b0;
        end else if (pcWrite) begin
            pc_reg <= pcNext_IF;
        end
    end
    assign pc_IF = pc_reg;

    // pc + 4
    Adder adder_if_pcplus4(
        .a(pc_IF),
        .b(32'd4),
        .sum(pcPlus4_IF)
    );

    // Instruction Memory
    InstructionMemory imem(
        .readAddr(pc_IF),
        .inst(instr_IF)
    );

endmodule
