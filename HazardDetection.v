module HazardDetection(
    input  [4:0] rs1_ID,
    input  [4:0] rs2_ID,
    input  [4:0] rd_EX,
    input        memRead_EX,

    output reg stallF,
    output reg stallD,
    output reg flushE
);

always @(*) begin
    stallF = 0;
    stallD = 0;
    flushE = 0;

    // load-use hazard
    if (memRead_EX && (rd_EX != 0) &&
       ((rd_EX == rs1_ID) || (rd_EX == rs2_ID))) 
    begin
        stallF = 1;
        stallD = 1;
        flushE = 1;
    end
end

endmodule