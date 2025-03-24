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
        " | IF.pc=%h | ID.instr=%b rs1_ID=%d rs2_ID=%d | EX.pc=%h EX.alu=%d zero=%b branchTaken=%b regWrite_WB=%b finalWBData=%d rd_WB=%d, memWrite_EX=%b",
        riscv_DUT.pc_IF,
        riscv_DUT.instr_ID,
        riscv_DUT.rs1_ID,
        riscv_DUT.rs2_ID,
        riscv_DUT.pc_EX,
        riscv_DUT.aluResult_EX,
        riscv_DUT.zero_EX,
        riscv_DUT.branchTaken_EX,
        riscv_DUT.regWrite_WB,
        riscv_DUT.finalWBData,
        riscv_DUT.rd_WB,
        riscv_DUT.memWrite_EX,
        riscv_DUT.writeData_MEM
        // Possibly add MEM or WB signals
    );
    // Run for a sufficient number of cycles
    #3000 $finish;
end

endmodule
