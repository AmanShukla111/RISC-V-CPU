module ImmGen #(parameter Width = 32) (
    input  [31:0] instruction,
    output reg [31:0] imm
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-type
            7'b0000011, // LOAD
            7'b0010011, // I-type ALU
            7'b1100111: // JALR
                // immediate is instruction[31:20], sign-extended
                imm = {{20{instruction[31]}}, instruction[31:20]};

            // S-type
            7'b0100011: // STORE
                imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type
            7'b1100011: // BRANCH
                imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8]};

            // U-type
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm = {instruction[31:12], 12'b0};

            // J-type
            7'b1101111: // JAL
                imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21]};

            // default
            default: imm = 32'b0;
        endcase
    end

endmodule
