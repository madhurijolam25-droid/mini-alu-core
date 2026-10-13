// =============================================================================
// flag_register.v
// 4-bit synchronous flag register: {V, N, C, Z} = bits {3,2,1,0}.
// Loads alu.next_flags when flag_write_en is asserted; otherwise holds.
// =============================================================================
`timescale 1ns / 1ps

module flag_register (
    input  wire       clk,
    input  wire       rst_n,
    input  wire        flag_write_en,
    input  wire [3:0]  next_flags,
    output reg  [3:0]  flags
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flags <= 4'b0000;
        end else if (flag_write_en) begin
            flags <= next_flags;
        end
    end

endmodule
