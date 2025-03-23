//------------------//
//   StageMEM.v
//------------------//
`include "WrapperMemory.v"

module StageMEM(
    input         clk,
    input         run,
    input         memWrite_MEM,
    input         memRead_MEM,
    input  [31:0] aluResult_MEM,
    input  [31:0] writeData_MEM,
    input  [2:0]  funct3_EX,    // if needed for partial store
    output [31:0] memReadData_out
);

    WrapperMemory wmem(
        .clk(clk),
        .rst(run),
        .memWrite(memWrite_MEM),
        .memRead(memRead_MEM),
        .address(aluResult_MEM),
        .writeData(writeData_MEM),
        .funct3(funct3_EX),
        .readData(memReadData_out)
    );

endmodule
