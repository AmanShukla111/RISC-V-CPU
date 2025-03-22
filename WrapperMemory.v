module WrapperMemory(
    input         clk,
    input         rst,    
    input         memWrite,
    input         memRead,
    input  [31:0] address,  
    input  [31:0] writeData,
    input  [2:0]  funct3,   
    output [31:0] readData
);

    // --------------------------------------------------
    // 1) Internal signals for the raw 32-bit read/write
    // --------------------------------------------------
    wire [31:0] mem_read_data;
    reg  [31:0] mem_write_data;
    reg         mem_write_en; 

    // **Declare these at module scope** (not inside always block!)
    reg  [31:0] modifiedWord;
    reg  [31:0] finalReadData;

    wire [1:0] byteOffset = address[1:0];

    // --------------------------------------------------
    // 2) Instantiate the Original DataMemory
    // --------------------------------------------------
    DataMemory dataMem_inst(
        .rst(rst),
        .clk(clk),
        .memWrite(mem_write_en),      
        .memRead(memRead),
        .address(address),
        .writeData(mem_write_data),
        .readData(mem_read_data)
    );

    // --------------------------------------------------
    // 3) Partial-Store Logic (SB, SH)
    // --------------------------------------------------
    always @(*) begin
        // By default
        mem_write_data = writeData;
        mem_write_en   = memWrite;

        if (memWrite) begin
            case (funct3)
                3'b000: begin // SB
                    // 1) read existing word from mem_read_data
                    // 2) modify the relevant byte
                    modifiedWord = mem_read_data;
                    case (byteOffset)
                        2'b00: modifiedWord[7:0]   = writeData[7:0];
                        2'b01: modifiedWord[15:8]  = writeData[7:0];
                        2'b10: modifiedWord[23:16] = writeData[7:0];
                        2'b11: modifiedWord[31:24] = writeData[7:0];
                    endcase
                    // 3) final write data
                    mem_write_data = modifiedWord;
                end

                3'b001: begin // SH
                    modifiedWord = mem_read_data;
                    case (byteOffset)
                        2'b00: modifiedWord[15:0]  = writeData[15:0];
                        2'b01: modifiedWord[23:8]  = writeData[15:0];
                        2'b10: modifiedWord[31:16] = writeData[15:0];
                    endcase
                    mem_write_data = modifiedWord;
                end

                3'b010: begin // SW
                    mem_write_data = writeData;
                end

                default: begin
                    mem_write_data = writeData;
                end
            endcase
        end
    end

    // --------------------------------------------------
    // 4) Partial-Load Logic (LB, LH, LBU, LHU, LW)
    // --------------------------------------------------
    always @(*) begin
        if (memRead) begin
            case (funct3)
                3'b000: begin // LB
                    case (byteOffset)
                        2'b00: finalReadData = {{24{mem_read_data[7]}},  mem_read_data[7:0]};
                        2'b01: finalReadData = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                        2'b10: finalReadData = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                        2'b11: finalReadData = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
                    endcase
                end

                3'b001: begin // LH
                    case (byteOffset)
                        2'b00: finalReadData = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
                        2'b01: finalReadData = {{16{mem_read_data[23]}}, mem_read_data[23:8]};
                        2'b10: finalReadData = {{16{mem_read_data[31]}}, mem_read_data[31:16]};
                        default: finalReadData = mem_read_data;
                    endcase
                end

                3'b010: begin // LW
                    finalReadData = mem_read_data;
                end

                3'b100: begin // LBU
                    case (byteOffset)
                        2'b00: finalReadData = {24'b0, mem_read_data[7:0]};
                        2'b01: finalReadData = {24'b0, mem_read_data[15:8]};
                        2'b10: finalReadData = {24'b0, mem_read_data[23:16]};
                        2'b11: finalReadData = {24'b0, mem_read_data[31:24]};
                    endcase
                end

                3'b101: begin // LHU
                    case (byteOffset)
                        2'b00: finalReadData = {16'b0, mem_read_data[15:0]};
                        2'b01: finalReadData = {16'b0, mem_read_data[23:8]};
                        2'b10: finalReadData = {16'b0, mem_read_data[31:16]};
                        default: finalReadData = mem_read_data;
                    endcase
                end

                default: begin
                    finalReadData = mem_read_data;
                end
            endcase
        end else begin
            finalReadData = 32'b0;
        end
    end

    assign readData = finalReadData;

endmodule
