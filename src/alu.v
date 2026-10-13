// =============================================================================
// alu.v
// Combinational 16-bit ALU for MiniALU Core.
// Computes the result and the NEXT flag-register value for every opcode.
// Flag bit order (current_flags / next_flags): {V, N, C, Z} = bits {3,2,1,0}.
// =============================================================================
`timescale 1ns / 1ps

module alu (
    input  wire [3:0]  opcode,
    input  wire [15:0] rd_data,
    input  wire [15:0] rs_data,
    input  wire [9:0]  imm10,
    input  wire [3:0]  current_flags,
    output reg  [15:0] result,
    output reg  [3:0]  next_flags
);

    // ---------------------------------------------------------------------
    // Opcode encodings (must match instruction_decode.v exactly)
    // ---------------------------------------------------------------------
    localparam [3:0] OPC_ADD = 4'b0000;
    localparam [3:0] OPC_SUB = 4'b0001;
    localparam [3:0] OPC_AND = 4'b0010;
    localparam [3:0] OPC_OR  = 4'b0011;
    localparam [3:0] OPC_XOR = 4'b0100;
    localparam [3:0] OPC_NOT = 4'b0101;
    localparam [3:0] OPC_SHL = 4'b0110;
    localparam [3:0] OPC_SHR = 4'b0111;
    localparam [3:0] OPC_INC = 4'b1000;
    localparam [3:0] OPC_DEC = 4'b1001;
    localparam [3:0] OPC_CMP = 4'b1010;
    localparam [3:0] OPC_MOV = 4'b1011;
    localparam [3:0] OPC_LDI = 4'b1100;
    localparam [3:0] OPC_OUT = 4'b1101;
    // 4'b1110, 4'b1111 : reserved, handled by the `default` case below

    // ---------------------------------------------------------------------
    // Shared intermediate terms (computed every cycle, used where relevant)
    // ---------------------------------------------------------------------
    reg [16:0] add_wide;   // 17-bit result for ADD, to capture carry-out
    reg [16:0] inc_wide;   // 17-bit result for INC, to capture carry-out
    reg [15:0] sub_result; // 16-bit result for SUB / CMP
    reg [15:0] dec_result; // 16-bit result for DEC
    reg        add_c, add_v;
    reg        sub_c, sub_v;
    reg        inc_c, inc_v;
    reg        dec_c, dec_v;

    always @(*) begin
        // ---- shared arithmetic (always computed; only used by the
        //      opcodes that need it) ----
        add_wide   = {1'b0, rd_data} + {1'b0, rs_data};
        add_c      = add_wide[16];
        add_v      = (rd_data[15] == rs_data[15]) && (add_wide[15] != rd_data[15]);

        sub_result = rd_data - rs_data;
        sub_c      = (rd_data >= rs_data) ? 1'b1 : 1'b0;
        sub_v      = (rd_data[15] != rs_data[15]) && (sub_result[15] != rd_data[15]);

        inc_wide   = {1'b0, rd_data} + 17'h00001;
        inc_c      = inc_wide[16];
        inc_v      = (rd_data[15] == 1'b0) && (inc_wide[15] == 1'b1);

        dec_result = rd_data - 16'h0001;
        dec_c      = (rd_data != 16'h0000) ? 1'b1 : 1'b0;
        dec_v      = (rd_data[15] == 1'b1) && (dec_result[15] == 1'b0);

        // ---- default: pass flags through unchanged, drive a safe result.
        //      Every branch below overrides only what that instruction
        //      actually defines (Section 6.3 of the ISA sheet). ----
        result     = 16'h0000;
        next_flags = current_flags;

        case (opcode)
            OPC_ADD: begin
                result        = add_wide[15:0];
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = add_c;
                next_flags[2] = result[15];
                next_flags[3] = add_v;
            end

            OPC_SUB: begin
                result        = sub_result;
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = sub_c;
                next_flags[2] = result[15];
                next_flags[3] = sub_v;
            end

            OPC_AND: begin
                result        = rd_data & rs_data;
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
                // C, V: held (already defaulted to current_flags above)
            end

            OPC_OR: begin
                result        = rd_data | rs_data;
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
            end

            OPC_XOR: begin
                result        = rd_data ^ rs_data;
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
            end

            OPC_NOT: begin
                result        = ~rd_data;
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
            end

            OPC_SHL: begin
                result        = rd_data << 1;
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = rd_data[15];   // bit shifted out
                next_flags[2] = result[15];
            end

            OPC_SHR: begin
                result        = rd_data >> 1;
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = rd_data[0];    // bit shifted out
                next_flags[2] = result[15];
            end

            OPC_INC: begin
                result        = inc_wide[15:0];
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = inc_c;
                next_flags[2] = result[15];
                next_flags[3] = inc_v;
            end

            OPC_DEC: begin
                result        = dec_result;
                next_flags[0] = (result == 16'h0000);
                next_flags[1] = dec_c;
                next_flags[2] = result[15];
                next_flags[3] = dec_v;
            end

            OPC_CMP: begin
                // Same math as SUB; the result is simply never written
                // back (instruction_decode drives reg_write_en = 0 for CMP).
                result        = sub_result;
                next_flags[0] = (sub_result == 16'h0000);
                next_flags[1] = sub_c;
                next_flags[2] = sub_result[15];
                next_flags[3] = sub_v;
            end

            OPC_MOV: begin
                result        = rs_data;
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
            end

            OPC_LDI: begin
                result        = {6'b000000, imm10};
                next_flags[0] = (result == 16'h0000);
                next_flags[2] = result[15];
            end

            OPC_OUT: begin
                // out_register sources register_file.rd_data directly, not
                // this result, and flag_write_en is 0 for OUT, so both of
                // these are inert -- restated explicitly for clarity.
                result     = rd_data;
                next_flags = current_flags;
            end

            default: begin
                // Reserved opcodes 4'b1110 and 4'b1111: fully defined,
                // inert, no result and no flag change.
                result     = 16'h0000;
                next_flags = current_flags;
            end
        endcase
    end

endmodule
