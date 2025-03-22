module ALUCtrl(
    input      [1:0] ALUOp,
    input      [2:0] funct3,
    input            funct7,
    output reg [3:0] ALUCtl
);

    // Example localparams for ALU operations
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLL  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_SLT  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    always @(*) begin
        case (ALUOp)
            2'b00: ALUCtl = ALU_ADD;   // LW, SW, ADDI, JAL, etc.
            2'b01: ALUCtl = ALU_SUB;   // Branch instructions do SUB/compare
            2'b10: begin
                // R-type or I-type decode
                // Now check funct3 & funct7
                case (funct3)
                    3'b000: begin
                        // ADD or SUB?
                        if (funct7 == 1'b1) 
                            ALUCtl = ALU_SUB;  // SUB
                        else
                            ALUCtl = ALU_ADD;  // ADD
                    end
                    3'b001: ALUCtl = ALU_SLL;  // SLL or SLLI
                    3'b010: ALUCtl = ALU_SLT;  // SLT or SLTI
                    3'b011: ALUCtl = ALU_SLTU; // SLTU or SLTIU
                    3'b100: ALUCtl = ALU_XOR;  // XOR
                    3'b101: begin
                        // SRL or SRA?
                        if (funct7 == 1'b1)
                            ALUCtl = ALU_SRA;  // SRA
                        else
                            ALUCtl = ALU_SRL;  // SRL
                    end
                    3'b110: ALUCtl = ALU_OR;   // OR
                    3'b111: ALUCtl = ALU_AND;  // AND
                    default: ALUCtl = ALU_ADD; // default
                endcase
            end
            default: ALUCtl = ALU_ADD;
        endcase
    end
endmodule
