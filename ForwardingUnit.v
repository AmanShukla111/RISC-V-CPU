module ForwardingUnit(
    input  [4:0] rs1_EX,
    input  [4:0] rs2_EX,
    input  [4:0] rd_MEM,
    input  [4:0] rd_WB,
    input        regWrite_MEM,
    input        regWrite_WB,
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);
    // The typical encoding:
    // forwardA = 2'b00 => no forwarding, use ID/EX data
    // forwardA = 2'b10 => forward from EX/MEM stage
    // forwardA = 2'b01 => forward from MEM/WB stage

    always @(*) begin
        // Default: no forwarding
        forwardA = 2'b00;
        forwardB = 2'b00;

        // Check MEM stage for hazards
        // If MEM stage is writing and rd_MEM == rs1_EX => forward A from MEM
        if (regWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs1_EX))
            forwardA = 2'b10;

        // If MEM stage is writing and rd_MEM == rs2_EX => forward B from MEM
        if (regWrite_MEM && (rd_MEM != 0) && (rd_MEM == rs2_EX))
            forwardB = 2'b10;

        // Check WB stage for hazards
        // If WB stage is writing and rd_WB == rs1_EX => forward A from WB
        // We check WB after MEM so it overrides if both match
        if (regWrite_WB && (rd_WB != 0) && (rd_WB == rs1_EX))
            forwardA = 2'b01;

        if (regWrite_WB && (rd_WB != 0) && (rd_WB == rs2_EX))
            forwardB = 2'b01;
    end

endmodule
