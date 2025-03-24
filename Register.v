module Register (
    input clk,
    input rst,
    input [4:0] readReg1_ID,
    input [4:0] readReg2_ID,
    output [31:0] readData1_ID,
    output [31:0] readData2_ID,
    input regWrite_WB,
    input [4:0] writeReg_WB,
    input [31:0] writeData_WB
);

    reg [31:0] regs [0:31];

    // Asynchronous Read for ID Stage
    assign readData1_ID = (readReg1_ID != 0) ? regs[readReg1_ID] : 0;
    assign readData2_ID = (readReg2_ID != 0) ? regs[readReg2_ID] : 0;
    integer i;

    // Synchronous Write (WB Stage)
    always @(posedge clk) begin
        if (~rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= (i == 2) ? 32'd128 : 0;  // Initialize x2 with 128
        end
        else if (regWrite_WB && writeReg_WB != 0) begin
            regs[writeReg_WB] <= writeData_WB;
        end
    end

endmodule
