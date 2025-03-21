module ImmGen #(parameter Width = 32) (
    input [Width-1:0] inst,
    output reg signed [Width-1:0] imm
);
    // ImmGen generate imm value based on opcode and instruction type

    wire [6:0] opcode = inst[6:0];

    always @(*) 
    begin
        case(opcode)
            // R-type instructions (ADD, SUB) don't use immediates
            7'b0110011: imm = 32'b0;

            // I-type instructions (LW, ADDI, SLLI, ORI)
            7'b0000011, // LW
            7'b0010011: // ADDI, SLLI, ORI
                case(inst[14:12]) // funct3
                    3'b001: imm = {27'b0, inst[24:20]}; // SLLI
                    default: imm = {{20{inst[31]}}, inst[31:20]}; // LW, ADDI, ORI
                endcase

            // S-type instructions (SW)
            7'b0100011: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};

            // B-type instructions (BEQ, BGT)
            7'b1100011: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

            // J-type instruction (JAL)
            7'b1101111: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

            // Default case
            default: imm = 32'b0; // Default to 0 for unsupported opcodes
        endcase
    end
            
endmodule