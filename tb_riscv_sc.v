`include "PipelinedCPU.v"
`timescale 1ns/1ns

module tb_riscv_sc;

reg clk;
reg start;

// Instantiate the CPU (keep the original port connections)
PipelinedCPU riscv_DUT(
    .clk(clk),
    .start(start)
);

// Clock generation
always #5 clk = ~clk;

// Test sequence
initial begin
    $dumpfile("cpu_simulation.vcd");
    $dumpvars(0, tb_riscv_sc);

    clk = 0;
    start = 0;
    #10 start = 1;

    $monitor($time, 
        " | IF.pc=%h | ID.instr=%h | EX.pc=%h EX.alu=%d zero=%b branchTaken=%b regWrite_WB=%b finalWBData=%d",
        riscv_DUT.pc_IF,
        riscv_DUT.instr_ID,
        riscv_DUT.pc_EX,
        riscv_DUT.aluResult_EX,
        riscv_DUT.zero_EX,
        riscv_DUT.branchTaken_EX,
        riscv_DUT.regWrite_WB,
        riscv_DUT.finalWBData,
        // Possibly add MEM or WB signals
    );
    // Run for a sufficient number of cycles
    #3000 $finish;
end

endmodule
