// =============================================================================
// minialu_core_top.v
// Top-level: wires instruction_decode -> register_file + alu -> flag_register
// and out_register together. One instruction executes per clock cycle.
// =============================================================================
`timescale 1ns / 1ps

module minialu_core_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] instr,
    output wire [15:0] OUT,
    output wire [3:0]  FLAGS
);

    // Decode -> everything
    wire [3:0]  opcode;
    wire [1:0]  rd_sel;
    wire [1:0]  rs_sel;
    wire [9:0]  imm10;
    wire        reg_write_en;
    wire        flag_write_en;
    wire        out_write_en;

    // Register file <-> ALU
    wire [15:0] rd_data;
    wire [15:0] rs_data;
    wire [15:0] alu_result;

    // Flag register <-> ALU
    wire [3:0]  current_flags;
    wire [3:0]  next_flags;

    instruction_decode u_decode (
        .instr         (instr),
        .opcode        (opcode),
        .rd_sel        (rd_sel),
        .rs_sel        (rs_sel),
        .imm10         (imm10),
        .reg_write_en  (reg_write_en),
        .flag_write_en (flag_write_en),
        .out_write_en  (out_write_en)
    );

    register_file u_regfile (
        .clk        (clk),
        .rst_n      (rst_n),
        .rd_sel     (rd_sel),
        .rs_sel     (rs_sel),
        .write_en   (reg_write_en),
        .write_data (alu_result),
        .rd_data    (rd_data),
        .rs_data    (rs_data)
    );

    alu u_alu (
        .opcode        (opcode),
        .rd_data       (rd_data),
        .rs_data       (rs_data),
        .imm10         (imm10),
        .current_flags (current_flags),
        .result        (alu_result),
        .next_flags    (next_flags)
    );

    flag_register u_flags (
        .clk           (clk),
        .rst_n         (rst_n),
        .flag_write_en (flag_write_en),
        .next_flags    (next_flags),
        .flags         (current_flags)
    );

    out_register u_out (
        .clk          (clk),
        .rst_n        (rst_n),
        .out_write_en (out_write_en),
        .write_data   (rd_data),
        .out_data     (OUT)
    );

    assign FLAGS = current_flags;

endmodule
