// =============================================================================
// register_file.v
// 4 x 16-bit general-purpose registers (R0-R3). Dual combinational read,
// single synchronous write. The register addressed by rd_sel is read as the
// first operand AND written as the destination in the same cycle.
// =============================================================================
`timescale 1ns / 1ps

module register_file (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  rd_sel,
    input  wire [1:0]  rs_sel,
    input  wire        write_en,
    input  wire [15:0] write_data,
    output wire [15:0] rd_data,
    output wire [15:0] rs_data
);

    reg [15:0] regfile [0:3];
    integer    i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                regfile[i] <= 16'h0000;
            end
        end else if (write_en) begin
            regfile[rd_sel] <= write_data;
        end
    end

    // Combinational read: reflects the pre-write value on the same cycle
    // a write happens (standard register-file read-before-write behavior).
    assign rd_data = regfile[rd_sel];
    assign rs_data = regfile[rs_sel];

endmodule
