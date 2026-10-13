// =============================================================================
// tb_minialu_core.v
// Self-checking testbench for minialu_core_top.
//
// Coverage:
//   - All 14 defined opcodes, at least one directed test each
//   - Both reserved opcodes (4'b1110, 4'b1111)
//   - Every edge case listed in Section 6.4 of the ISA sheet:
//       Rd == Rs, SUB/CMP Rd,Rd, NOT 0x0000, INC 0xFFFF wrap,
//       DEC 0x0000 wrap, MOV Rd,Rd, reserved-opcode safety, imm10 range
//   - CMP's non-destructive property (Rd unchanged)
//   - OUT's flag-preserving property (FLAGS unchanged by OUT)
//   - Reset behavior
//
// Internal register contents (R0-R3) are checked via hierarchical
// reference into the DUT (simulation-only -- not synthesized, not part
// of the DUT's functional interface) since the design intentionally
// exposes no register-debug ports.
// =============================================================================
`timescale 1ns / 1ps

module tb_minialu_core;

    // ---------------------------------------------------------------------
    // Opcode encodings (for building instruction words below)
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
    localparam [3:0] OPC_RSV0 = 4'b1110;
    localparam [3:0] OPC_RSV1 = 4'b1111;

    localparam [1:0] R0 = 2'b00, R1 = 2'b01, R2 = 2'b10, R3 = 2'b11;

    // ---------------------------------------------------------------------
    // DUT connections
    // ---------------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [15:0] instr;
    wire [15:0] OUT;
    wire [3:0]  FLAGS;

    integer pass_count;
    integer fail_count;

    minialu_core_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .instr (instr),
        .OUT   (OUT),
        .FLAGS (FLAGS)
    );

    // ---------------------------------------------------------------------
    // Clock: 10ns period (simulation only -- unrelated to synthesis timing)
    // ---------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------------
    // Instruction-word builders (match Section 6.1's bit layout exactly)
    // ---------------------------------------------------------------------
    function [15:0] make_r;
        input [3:0] op;
        input [1:0] rd;
        input [1:0] rs;
        begin
            make_r = {op, rd, rs, 8'b0};
        end
    endfunction

    function [15:0] make_s;
        input [3:0] op;
        input [1:0] rd;
        begin
            make_s = {op, rd, 10'b0};
        end
    endfunction

    function [15:0] make_i;
        input [3:0] op;
        input [1:0] rd;
        input [9:0] imm;
        begin
            make_i = {op, rd, imm};
        end
    endfunction

    // ---------------------------------------------------------------------
    // Drive one instruction for one clock edge, then settle
    // ---------------------------------------------------------------------
    task apply;
        input [15:0] i_word;
        begin
            instr = i_word;
            @(posedge clk);
            #1; // let non-blocking register updates settle
        end
    endtask

    // ---------------------------------------------------------------------
    // Checkers
    // ---------------------------------------------------------------------
    task check16;
        input [8*64-1:0] name;
        input [15:0]     actual;
        input [15:0]     expected;
        begin
            if (actual !== expected) begin
                $display("FAIL [%0t] %0s : expected=0x%04h actual=0x%04h", $time, name, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [%0t] %0s : 0x%04h", $time, name, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    task check4;
        input [8*64-1:0] name;
        input [3:0]      actual;
        input [3:0]      expected;
        begin
            if (actual !== expected) begin
                $display("FAIL [%0t] %0s : expected=%b actual=%b (VNCZ)", $time, name, expected, actual);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [%0t] %0s : %b (VNCZ)", $time, name, actual);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Convenience: read register file contents directly for simulation checks
    `define REG(n) dut.u_regfile.regfile[n]

    // ---------------------------------------------------------------------
    // Main test sequence
    // ---------------------------------------------------------------------
    initial begin
        $dumpfile("tb_minialu_core.vcd");
        $dumpvars(0, tb_minialu_core);

        pass_count = 0;
        fail_count = 0;
        instr      = 16'h0000;
        rst_n      = 1'b0;

        // ---- Reset ----
        repeat (2) @(posedge clk);
        #1;
        check16("reset: R0", `REG(0), 16'h0000);
        check16("reset: R1", `REG(1), 16'h0000);
        check16("reset: R2", `REG(2), 16'h0000);
        check16("reset: R3", `REG(3), 16'h0000);
        check16("reset: OUT", OUT, 16'h0000);
        check4 ("reset: FLAGS", FLAGS, 4'b0000);

        rst_n = 1'b1;
        @(posedge clk);
        #1;

        // ---- LDI: basic load + immediate edge values (min and max) ----
        apply(make_i(OPC_LDI, R0, 10'd5));
        check16("LDI R0,5 -> R0", `REG(0), 16'h0005);
        check4 ("LDI R0,5 -> FLAGS", FLAGS, 4'b0000);

        apply(make_i(OPC_LDI, R1, 10'd10));
        check16("LDI R1,10 -> R1", `REG(1), 16'h000A);

        apply(make_i(OPC_LDI, R2, 10'd1023)); // max imm10 value
        check16("LDI R2,1023 -> R2", `REG(2), 16'h03FF);
        check4 ("LDI R2,1023 -> FLAGS (N must be 0)", FLAGS, 4'b0000);

        apply(make_i(OPC_LDI, R3, 10'd0));    // min imm10 value, also sets Z
        check16("LDI R3,0 -> R3", `REG(3), 16'h0000);
        check4 ("LDI R3,0 -> FLAGS (Z=1)", FLAGS, 4'b0001);

        // ---- ADD, including Rd == Rs edge case ----
        apply(make_r(OPC_ADD, R0, R1)); // R0 = 5 + 10 = 15
        check16("ADD R0,R1 -> R0", `REG(0), 16'h000F);
        check4 ("ADD R0,R1 -> FLAGS", FLAGS, 4'b0000);

        apply(make_r(OPC_ADD, R0, R0)); // Rd==Rs : R0 = 15 + 15 = 30
        check16("ADD R0,R0 (Rd==Rs) -> R0", `REG(0), 16'h001E);
        check4 ("ADD R0,R0 -> FLAGS", FLAGS, 4'b0000);

        // ---- SUB, including Rd == Rs edge case ----
        apply(make_r(OPC_SUB, R0, R1)); // R0 = 30 - 10 = 20, no borrow -> C=1
        check16("SUB R0,R1 -> R0", `REG(0), 16'h0014);
        check4 ("SUB R0,R1 -> FLAGS (C=1)", FLAGS, 4'b0010);

        apply(make_r(OPC_SUB, R0, R0)); // Rd==Rs : always Z=1,C=1,N=0,V=0
        check16("SUB R0,R0 (Rd==Rs) -> R0", `REG(0), 16'h0000);
        check4 ("SUB R0,R0 -> FLAGS (Z=1,C=1)", FLAGS, 4'b0011);

        // ---- AND / OR / XOR ----
        apply(make_i(OPC_LDI, R0, 10'd5));  // R0 = 5
        apply(make_r(OPC_AND, R0, R1));     // R0 = 5 & 10 = 0
        check16("AND R0,R1 -> R0", `REG(0), 16'h0000);
        check4 ("AND R0,R1 -> FLAGS (Z=1, C/V held=1/0)", FLAGS, 4'b0011);

        apply(make_r(OPC_OR, R0, R1));      // R0 = 0 | 10 = 10
        check16("OR R0,R1 -> R0", `REG(0), 16'h000A);
        check4 ("OR R0,R1 -> FLAGS (Z=0, C/V held=1/0)", FLAGS, 4'b0010);

        apply(make_r(OPC_XOR, R0, R1));     // R0 = 10 ^ 10 = 0
        check16("XOR R0,R1 -> R0", `REG(0), 16'h0000);
        check4 ("XOR R0,R1 -> FLAGS (Z=1)", FLAGS, 4'b0011);

        // ---- NOT, including the 0x0000 edge case ----
        apply(make_s(OPC_NOT, R0));         // R0 = ~0x0000 = 0xFFFF
        check16("NOT R0 on 0x0000 -> R0", `REG(0), 16'hFFFF);
        check4 ("NOT 0x0000 -> FLAGS (Z=0,N=1,C held=1)", FLAGS, 4'b0110);

        // ---- SHL / SHR on the resulting 0xFFFF / 0xFFFE chain ----
        apply(make_s(OPC_SHL, R0));         // 0xFFFF << 1 = 0xFFFE, C=1(old bit15)
        check16("SHL R0 (0xFFFF) -> R0", `REG(0), 16'hFFFE);
        check4 ("SHL -> FLAGS (C=1,N=1)", FLAGS, 4'b0110);

        apply(make_s(OPC_SHR, R0));         // 0xFFFE >> 1 = 0x7FFF, C=0(old bit0)
        check16("SHR R0 (0xFFFE) -> R0", `REG(0), 16'h7FFF);
        check4 ("SHR -> FLAGS (C=0,N=0)", FLAGS, 4'b0000);

        // ---- INC: normal overflow case, then the 0xFFFF wrap edge case ----
        apply(make_s(OPC_INC, R0));         // 0x7FFF + 1 = 0x8000 (signed overflow)
        check16("INC R0 (0x7FFF) -> R0", `REG(0), 16'h8000);
        check4 ("INC 0x7FFF -> FLAGS (N=1,V=1)", FLAGS, 4'b1100);

        apply(make_i(OPC_LDI, R0, 10'd0));
        apply(make_s(OPC_NOT, R0));         // R0 = 0xFFFF
        apply(make_s(OPC_INC, R0));         // edge case: INC on 0xFFFF wraps
        check16("INC R0 (0xFFFF) wrap -> R0", `REG(0), 16'h0000);
        check4 ("INC 0xFFFF -> FLAGS (Z=1,C=1,V=0)", FLAGS, 4'b0011);

        // ---- DEC: the 0x0000 wrap edge case ----
        apply(make_s(OPC_DEC, R0));         // edge case: DEC on 0x0000 wraps
        check16("DEC R0 (0x0000) wrap -> R0", `REG(0), 16'hFFFF);
        check4 ("DEC 0x0000 -> FLAGS (Z=0,C=0,N=1,V=0)", FLAGS, 4'b0100);

        // ---- CMP: non-destructive property, and Rd==Rs edge case ----
        apply(make_i(OPC_LDI, R0, 10'd7));
        apply(make_i(OPC_LDI, R1, 10'd7));
        apply(make_r(OPC_CMP, R0, R1));     // 7-7=0 for flags only; R0 must NOT change
        check16("CMP R0,R1 : R0 unchanged", `REG(0), 16'h0007);
        check4 ("CMP R0,R1 -> FLAGS (Z=1,C=1)", FLAGS, 4'b0011);

        apply(make_r(OPC_CMP, R0, R0));     // Rd==Rs edge case: always Z=1,C=1,N=0,V=0
        check16("CMP R0,R0 (Rd==Rs) : R0 unchanged", `REG(0), 16'h0007);
        check4 ("CMP R0,R0 -> FLAGS (Z=1,C=1,N=0,V=0)", FLAGS, 4'b0011);

        // ---- MOV, including the Rd==Rs edge case ----
        apply(make_r(OPC_MOV, R1, R0));     // R1 <- R0 (= 7)
        check16("MOV R1,R0 -> R1", `REG(1), 16'h0007);
        check4 ("MOV R1,R0 -> FLAGS (Z=0,N=0,C held=1)", FLAGS, 4'b0010);

        apply(make_r(OPC_MOV, R0, R0));     // Rd==Rs edge case: no-op on value
        check16("MOV R0,R0 (Rd==Rs) : R0 unchanged", `REG(0), 16'h0007);
        check4 ("MOV R0,R0 -> FLAGS (Z=0,N=0,C held=1)", FLAGS, 4'b0010);

        // ---- OUT: correctness + flag-preservation property ----
        apply(make_s(OPC_OUT, R0));         // OUT <- R0 (=7); FLAGS must be unchanged
        check16("OUT R0 -> OUT", OUT, 16'h0007);
        check4 ("OUT R0 -> FLAGS unchanged", FLAGS, 4'b0010);

        // ---- Reserved opcodes: must be fully inert ----
        apply(make_r(OPC_RSV0, R0, R1));    // arbitrary operands, must change nothing
        check16("Reserved 1110 : R0 unchanged", `REG(0), 16'h0007);
        check16("Reserved 1110 : OUT unchanged", OUT, 16'h0007);
        check4 ("Reserved 1110 : FLAGS unchanged", FLAGS, 4'b0010);

        apply(make_i(OPC_RSV1, R2, 10'd999)); // arbitrary operands, must change nothing
        check16("Reserved 1111 : R2 unchanged", `REG(2), 16'h03FF);
        check16("Reserved 1111 : OUT unchanged", OUT, 16'h0007);
        check4 ("Reserved 1111 : FLAGS unchanged", FLAGS, 4'b0010);

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("----------------------------------------------------");
        $display("TOTAL: %0d passed, %0d failed", pass_count, fail_count);
        if (fail_count == 0) begin
            $display("RESULT: ALL TESTS PASSED");
        end else begin
            $display("RESULT: %0d TEST(S) FAILED", fail_count);
        end
        $display("----------------------------------------------------");

        $finish;
    end

endmodule
