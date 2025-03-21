module ALU (
    input [3:0] ALUCtl,
    input signed [31:0] A,B,
    output reg signed [31:0] ALUOut,
    output zero
);
    // ALU Control signals
    localparam ADD  = 4'b0010;
    localparam SUB  = 4'b0110;
    localparam AND  = 4'b0000;
    localparam OR   = 4'b0001;
    localparam SLT  = 4'b0111;
    localparam SLL  = 4'b1000;
    localparam CTZ = 4'b1010;

    always @(*) begin
        case (ALUCtl)
            ADD:  ALUOut = A + B;
            SUB:  ALUOut = A - B;
            AND:  ALUOut = A & B;
            OR:   ALUOut = A | B;
            CTZ: ALUOut = countTrailingZeros(A);
            SLT:  ALUOut = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            SLL:  ALUOut = A << B[4:0];
            default: ALUOut = 32'b0;
        endcase
    end

    // Zero flag, used for branch instructions
    assign zero = (ALUOut == 32'b0);

    function [31:0] countTrailingZeros(input [31:0] val);
        integer i;
        begin
            // default if val == 0, trailing zeros is 32
            countTrailingZeros = 32;
            for (i = 0; i < 32; i = i + 1) begin
                if (val[i] == 1'b1 && countTrailingZeros == 32) begin
                    countTrailingZeros = i; 
                end
            end
        end
    endfunction


endmodule
