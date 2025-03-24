module HazardDetection(
    input [4:0] rs1_ID,
    input [4:0] rs2_ID,
    input [4:0] rd_EX,
    input       memRead_EX,
    // Additional signals:
    input [4:0] rd_WB,
    input       regWrite_WB,
    input       isStore_ID,  // from control or decode
    output reg  stallF,
    output reg  stallD,
    output reg  flushE
);
    always @(*) begin
        // defaults
        stallF = 0;
        stallD = 0;
        flushE = 0;

        // Existing load-use hazard
        if (memRead_EX && ((rd_EX == rs1_ID) || (rd_EX == rs2_ID)) && (rd_EX != 0)) begin
            stallF = 1;
            stallD = 1;
        end

        // NEW: store data hazard
        // If current instruction is a store in ID,
        // and the *previous* instruction in WB writes the same register
        // that store needs for data (rs2_ID).
        // But the store's ID is happening one cycle *before* the previous instruction's WB.
        // => stall 1 cycle so that next cycle, the producer is in WB and store is in ID -> bypass works.
        if (isStore_ID && (rs2_ID != 0) && regWrite_WB && (rd_WB == rs2_ID)) begin
            stallF = 1;
            stallD = 1;
        end
    end
endmodule
