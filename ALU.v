module ALU(
    input  [3:0] ALUCtl,
    input  signed [31:0] A, B,
    output reg signed [31:0] ALUOut,
    output zero
);

    // Define ALU control codes for clarity
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110; // Logical shift right
    localparam ALU_SRA  = 4'b0111; // Arithmetic shift right
    localparam ALU_SLT  = 4'b1000; // Signed less-than
    localparam ALU_SLTU = 4'b1001; // Unsigned less-than

    always @(*) begin
        case (ALUCtl)
            ALU_ADD:  ALUOut = A + B;
            ALU_SUB:  ALUOut = A - B;
            ALU_AND:  ALUOut = A & B;
            ALU_OR:   ALUOut = A | B;
            ALU_XOR:  ALUOut = A ^ B;
            ALU_SLL:  ALUOut = A << B[4:0];
            ALU_SRL:  ALUOut = $unsigned(A) >> B[4:0];  // Cast operands to unsigned for logical shift
            ALU_SRA:  ALUOut = A >>> B[4:0];              // Arithmetic shift right keeps signed behavior
            ALU_SLT:  ALUOut = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            ALU_SLTU: ALUOut = ($unsigned(A) < $unsigned(B)) ? 32'd1 : 32'd0; // Cast for unsigned comparison
            default:  ALUOut = 32'b0;
        endcase
    end


    // Zero flag for branches (BEQ, BNE)
    assign zero = (ALUOut == 32'b0);

    function [31:0] countTrailingZeros(input [31:0] val);
        integer i;
        begin
            countTrailingZeros = 32;
            for (i = 0; i < 32; i = i + 1) begin
                if (val[i] == 1'b1 && countTrailingZeros == 32) begin
                    countTrailingZeros = i; 
                end
            end
        end
    endfunction

endmodule


