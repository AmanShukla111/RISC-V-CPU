//------------------//
//   StageWB.v
//------------------//
`include "Mux2to1.v"

module StageWB(
    input        memToReg_WB,
    input [31:0] aluResult_WB,
    input [31:0] memReadData_WB,
    output [31:0] finalWBData
);

    Mux2to1 #(32) mux_wb(
        .sel(memToReg_WB),
        .s0(aluResult_WB),
        .s1(memReadData_WB),
        .out(finalWBData)
    );

endmodule
