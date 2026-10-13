// =============================================================================
// instruction_decode.v
// Splits the 16-bit instruction word into opcode/operand fields and derives
// the three control signals every other module needs. Purely combinational.
// =============================================================================
`timescale 1ns / 1ps

module instruction_decode (
    input  wire [15:0] instr,
    output wire [3:0]  opcode,
    output wire [1:0]  rd_sel,
    output wire [1:0]  rs_sel,
    output wire [9:0]  imm10,
    output reg         reg_write_en,
    output reg         flag_write_en,
    output reg         out_write_en
);

    // ---------------------------------------------------------------------
    // Opcode encodings (must match alu.v exactly)
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
    // Field extraction -- fixed regardless of opcode (Section 6.1)
    // ---------------------------------------------------------------------
    assign opcode = instr[15:12];
    assign rd_sel = instr[11:10];
    assign rs_sel = instr[9:8];
    assign imm10  = instr[9:0];

    // ---------------------------------------------------------------------
    // Control signal generation -- every one of the 16 possible opcode
    // values is covered explicitly (14 defined + 2 reserved via `default`),
    // so no latch can ever be inferred here.
    // ---------------------------------------------------------------------
    always @(*) begin
        reg_write_en  = 1'b0;
        flag_write_en = 1'b0;
        out_write_en  = 1'b0;

        case (opcode)
            OPC_ADD: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_SUB: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_AND: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_OR : begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_XOR: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_NOT: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_SHL: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_SHR: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_INC: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_DEC: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_CMP: begin reg_write_en = 1'b0; flag_write_en = 1'b1; end // flags only
            OPC_MOV: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_LDI: begin reg_write_en = 1'b1; flag_write_en = 1'b1; end
            OPC_OUT: begin reg_write_en = 1'b0; flag_write_en = 1'b0; out_write_en = 1'b1; end
            default: begin reg_write_en = 1'b0; flag_write_en = 1'b0; out_write_en = 1'b0; end // reserved
        endcase
    end

endmodule
