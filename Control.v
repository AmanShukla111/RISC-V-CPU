module Control (
    input [6:0] opcode,
    input [2:0] funct3,
    output reg branch,
    output reg memRead,
    output reg memtoReg,
    output reg [1:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite
);

    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB)
                ALUOp = 2'b10;
                ALUSrc = 1'b0;
                memtoReg = 1'b0;
                regWrite = 1'b1;
                memRead = 1'b0;
                memWrite = 1'b0;
                branch = 1'b0;
            end
            7'b0010011: begin // I-type (ADDI, SLLI, ORI)
                if (funct3 == 3'b000) begin // ADDI
                    ALUOp = 2'b00; // Force addition for ADDI
                end
                else begin
                    ALUOp = 2'b10;
                end
                ALUSrc = 1'b1;
                memtoReg = 1'b0;
                regWrite = 1'b1;
                memRead = 1'b0;
                memWrite = 1'b0;
                branch = 1'b0;
            end
            7'b0001011: begin // CTZ
                ALUSrc   = 1'b0;
                regWrite = 1'b1;
                memRead  = 1'b0;
                memWrite = 1'b0;
                memtoReg = 1'b0;
                branch   = 1'b0;
                ALUOp    = 2'b11;
            end
            7'b0000011: begin // LW
                ALUOp = 2'b00;
                ALUSrc = 1'b1;
                memtoReg = 1'b1;
                regWrite = 1'b1;
                memRead = 1'b1;
                memWrite = 1'b0;
                branch = 1'b0;
            end
            7'b0100011: begin // SW
                ALUOp = 2'b00;
                ALUSrc = 1'b1;
                memtoReg = 1'bx;
                regWrite = 1'b0;
                memRead = 1'b0;
                memWrite = 1'b1;
                branch = 1'b0;
            end
            7'b1100011: begin // BEQ, BGT
                ALUOp = 2'b01;
                ALUSrc = 1'b0;
                memtoReg = 1'bx;
                regWrite = 1'b0;
                memRead = 1'b0;
                memWrite = 1'b0;
                branch = 1'b1;
            end
            7'b1101111: begin // JAL
                ALUOp = 2'b00;
                ALUSrc = 1'b0;
                memtoReg = 1'b0;
                regWrite = 1'b1;
                memRead = 1'b0;
                memWrite = 1'b0;
                branch = 1'b1;
            end
            default: begin
                ALUOp = 2'b00;
                ALUSrc = 1'b0;
                memtoReg = 1'b0;
                regWrite = 1'b0;
                memRead = 1'b0;
                memWrite = 1'b0;
                branch = 1'b0;
            end
        endcase
    end

endmodule
