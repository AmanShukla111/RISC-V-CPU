`include "SingleCycleCPU.v"
`timescale 1ns/1ns

module tb_riscv_sc;

reg clk;
reg start;

// Instantiate the CPU (keep the original port connections)
SingleCycleCPU riscv_DUT(
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

    // Monitor and display signals
    $monitor("Time=%0t, PC=%h, ALUoperand2=%h, Instruction=%h, ALU_Result=%d, ReadData1=%h, ReadData2=%h, WriteData=%h, Branch=%b, MemRead=%b, MemToReg=%b, MemWrite=%b, ALUSrc=%b, RegWrite=%b",
             $time, riscv_DUT.pc_current,riscv_DUT.alu_operand2, riscv_DUT.instruction, riscv_DUT.alu_result, 
             riscv_DUT.read_data1, riscv_DUT.read_data2, riscv_DUT.write_data, 
             riscv_DUT.branch, riscv_DUT.mem_read, riscv_DUT.mem_to_reg, 
             riscv_DUT.mem_write, riscv_DUT.alu_src, riscv_DUT.reg_write);

    // Run for a sufficient number of cycles
    #3000 $finish;
end

endmodule
