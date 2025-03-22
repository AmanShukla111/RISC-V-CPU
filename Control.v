module Control(
    input  [6:0] opcode,
    input  [2:0] funct3,    // Sometimes used to differentiate certain I-type ops
    output reg       branch,
    output reg       memRead,
    output reg       memtoReg,
    output reg [1:0] ALUOp,       // 2-bit code to pass on to ALUCtrl
    output reg       memWrite,
    output reg       ALUSrc,
    output reg       regWrite,
    output reg       jump         // for JAL/JALR if needed
);

    // Local parameters for major opcode groups
    localparam OP_RTYPE  = 7'b0110011;  // R-type (ADD, SUB, AND, OR, etc.)
    localparam OP_ITYPE  = 7'b0010011;  // I-type ALU (ADDI, ORI, SLTI, etc.)
    localparam OP_LOAD   = 7'b0000011;  // LB, LH, LW, LBU, LHU
    localparam OP_STORE  = 7'b0100011;  // SB, SH, SW
    localparam OP_BRANCH = 7'b1100011;  // BEQ, BNE, BLT, etc.
    localparam OP_JAL    = 7'b1101111;  // JAL
    localparam OP_JALR   = 7'b1100111;  // JALR
    localparam OP_LUI    = 7'b0110111;  // LUI
    localparam OP_AUIPC  = 7'b0010111;  // AUIPC

    // ALUOp encoding (you can define as you prefer):
    //   00 => Force ALU to do ADD (LW, SW, ADDI, JAL, etc.)
    //   01 => Branch (ALU does SUB, or compare in ALUCtrl)
    //   10 => R-type or I-type decode (funct3/funct7 in ALUCtrl)
    //   11 => Possibly custom or extra

    always @(*) begin
        // Default (safe) values for all signals
        branch   = 0;
        memRead  = 0;
        memtoReg = 0;
        memWrite = 0;
        ALUSrc   = 0;
        regWrite = 0;
        jump     = 0;
        ALUOp    = 2'b00; // default to 00 (often “ADD”)

        case (opcode)

        // ----------------------
        // R-type: 0110011
        // ----------------------
        OP_RTYPE: begin
            regWrite = 1;       // we write to rd
            ALUSrc   = 0;       // second operand is rs2
            ALUOp    = 2'b10;   // R-type decode in ALUCtrl
        end

        // ----------------------
        // I-type ALU: 0010011
        // (ADDI, ORI, ANDI, SLTI, etc.)
        // ----------------------
        OP_ITYPE: begin
            regWrite = 1;      // we write to rd
            ALUSrc   = 1;      // second operand is immediate
            // If it’s ADDI (funct3 == 3'b000), force ALUOp=00 => ADD
            // Otherwise, let ALUCtrl decode (ALUOp=10)
            if (funct3 == 3'b000) begin
                // ADDI => force add
                ALUOp = 2'b00;
            end else begin
                // e.g. ORI, ANDI, SLTI, etc. => decode in ALUCtrl
                ALUOp = 2'b10;
            end
        end

        // ----------------------
        // Loads: 0000011
        // ----------------------
        OP_LOAD: begin
            regWrite = 1;   // we write loaded data to rd
            memRead  = 1;   // read from memory
            memtoReg = 1;   // register gets data from memory
            ALUSrc   = 1;   // address = rs1 + offset
            // Use ALUOp=00 => ALU does ADD
        end

        // ----------------------
        // Stores: 0100011
        // ----------------------
        OP_STORE: begin
            memWrite = 1;   // store to memory
            ALUSrc   = 1;   // address = rs1 + offset
            // ALUOp=00 => ALU does ADD
        end

        // ----------------------
        // Branches: 1100011
        // ----------------------
        OP_BRANCH: begin
            branch = 1;     // might update PC if condition is met
            ALUSrc = 0;     // compare rs1 vs rs2
            ALUOp  = 2'b01; // let ALUCtrl interpret as “SUB / compare”
        end

        // ----------------------
        // JAL: 1101111
        // ----------------------
        OP_JAL: begin
            jump     = 1;   // unconditional jump
            regWrite = 1;   // write PC+4 to rd
            // Typically ALU does PC + immediate => ALUOp=00 => ADD
            ALUSrc   = 0;   // some designs do ALUSrc=1; depends on your immediate path
        end

        // ----------------------
        // JALR: 1100111
        // ----------------------
        OP_JALR: begin
            jump     = 1;
            regWrite = 1;
            ALUSrc   = 1;   // address = rs1 + immediate
            // ALUOp=00 => ADD
        end

        // ----------------------
        // LUI: 0110111
        // ----------------------
        OP_LUI: begin
            regWrite = 1;
            ALUSrc   = 1;   // 20-bit immediate (upper)
            // ALUOp=00 => interpret as “0 + imm” or bypass
        end

        // ----------------------
        // AUIPC: 0010111
        // ----------------------
        OP_AUIPC: begin
            regWrite = 1;
            ALUSrc   = 1;   // imm plus PC
            // ALUOp=00 => ADD
        end

        // ----------------------
        // Default / Unknown
        // ----------------------
        default: begin
            // Everything stays at default: no writes, no branch
        end

        endcase
    end

endmodule
