module ALUCtrl (
    input [1:0] ALUOp,
    input funct7,
    input [2:0] funct3,
    output reg [3:0] ALUCtl
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUCtl = 4'b0010; // LW, SW, JAL (add)
            2'b01: ALUCtl = 4'b0110; // BEQ, BGT (subtract)
            2'b10: begin // R-type or I-type
                case (funct3)
                    3'b000: ALUCtl = (funct7 == 1'b1) ? 4'b0110 : 4'b0010; // SUB or ADD
                    3'b001: ALUCtl = 4'b1000; // SLLI (shift left logical)
                    3'b010: ALUCtl = 4'b0111; // SLT or SLTI
                    3'b110: ALUCtl = 4'b0001; // ORI (OR)
                    default: ALUCtl = 4'b0000; // Undefined
                endcase
            end
            2'b11: ALUCtl = 4'b1010; // CTZ
            default: ALUCtl = 4'b0000; // Undefined
        endcase
    end

endmodule
