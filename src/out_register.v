// =============================================================================
// out_register.v
// 16-bit synchronous output register. Loads register_file.rd_data (the
// value of Rd named by an OUT instruction) when out_write_en is asserted.
// =============================================================================
`timescale 1ns / 1ps

module out_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        out_write_en,
    input  wire [15:0] write_data,
    output reg  [15:0] out_data
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= 16'h0000;
        end else if (out_write_en) begin
            out_data <= write_data;
        end
    end

endmodule
