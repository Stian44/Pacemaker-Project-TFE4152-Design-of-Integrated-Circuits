// pacemaker_tb.v
`timescale 1ns/1ps

module pacemaker_tb;
    // ---------------- scaled timing ----------------
    // 100 clock cycles = 1 second, so 40 BPM = 150 cycles between beats.
    localparam CLK_HZ  = 100;
    localparam BEAT_40 = CLK_HZ * 60 / 40;   // 150 cycles
    // Timer starts counting when R clears it. A heartbeat goes WAIT -> RESET
    // -> WAIT, which costs 2 cycles, so LIMIT = 150 - 2 makes the machine pace
    // only when no beat has come for more than 150 cycles (BPM < 40).
    localparam LIMIT   = BEAT_40 - 2;
    localparam MAX_MSG = 5;                  // print at most this many failures

    localparam [1:0] S_RESET = 2'b00, S_WAIT = 2'b01, S_PACE = 2'b10;

    reg  clk = 0, rst = 1, H = 0;
    wire T, R, P, A, B;

    pacemaker dut (.clk(clk), .rst(rst), .H(H), .T(T),
                   .R(R), .P(P), .A(A), .B(B));

    always #5 clk = ~clk;

    // ---------------- timer model ----------------
    // Cleared by R (state 00). T stays high until the next R.
    reg [15:0] cnt;
    assign T = (cnt >= LIMIT);

    always @(posedge clk) begin
        if (rst || R)         cnt <= 0;
        else if (cnt < LIMIT) cnt <= cnt + 1;
    end

    // ---------------- reference model (from the state table) ----------------
    // A heartbeat always leads to RESET, including when already in RESET.
    function [1:0] expected_next(input [1:0] s, input h, input t);
        case (s)
            S_RESET: expected_next = h ? S_RESET : S_WAIT;
            S_WAIT : expected_next = h ? S_RESET : (t ? S_PACE : S_WAIT);
            S_PACE : expected_next = S_RESET;
            default: expected_next = S_RESET;
        endcase
    endfunction

    function [8*5-1:0] name(input [1:0] s);
        case (s)
            S_RESET: name = "RESET";
            S_WAIT : name = "WAIT ";
            S_PACE : name = "PACE ";
            default: name = "ILLEG";
        endcase
    endfunction

    reg [1:0] ref_state;
    always @(posedge clk) begin
        if (rst) ref_state <= S_RESET;
        else     ref_state <= expected_next(ref_state, H, T);
    end

    // ---------------- per-cycle checker ----------------
    integer errors = 0, checks = 0, paces = 0, cyc = 0;

    always @(posedge clk) cyc = cyc + 1;

    always @(negedge clk) begin
        if (!rst) begin
            checks = checks + 1;
            if ({A,B} !== ref_state || {A,B} === 2'b11 ||
                R !== ({A,B} == S_RESET) || P !== ({A,B} == S_PACE)) begin
                errors = errors + 1;
                if (errors <= MAX_MSG)
                    $display("      FAIL at cycle %0d: state=%b (expected %b), R=%b, P=%b",
                             cyc, {A,B}, ref_state, R, P);
            end
            if (P) paces = paces + 1;
        end
    end

    // ---------------- helpers ----------------
    task tick; begin @(posedge clk); #1; end endtask

    // 'count' one-cycle H pulses spaced N cycles apart
    task beats(input integer N, input integer count);
        integer k;
        begin
            for (k = 0; k < count; k = k + 1) begin
                repeat (N-1) tick;
                H = 1; tick;
                H = 0;
            end
        end
    endtask

    task wait_pace(output integer c);
        begin
            @(negedge clk);
            while (!P) @(negedge clk);
            c = cyc;
        end
    endtask

    task check(input ok);
        begin
            checks = checks + 1;
            if (!ok) errors = errors + 1;
        end
    endtask

    task result(input integer e_start);
        begin
            if (errors == e_start) $display("PASS");
            else                   $display("FAIL (%0d errors)", errors - e_start);
        end
    endtask

    task scenario(input integer N, input expect_pace);
        integer p_start, n_paces, e_start;
        begin
            e_start = errors;
            p_start = paces;
            beats(N, 6);
            n_paces = paces - p_start;
            check((n_paces > 0) == expect_pace);
            $write("      %0d cycles      %0d.%0d BPM     %0d       %s    ",
                   N, CLK_HZ*60/N, (CLK_HZ*600/N)%10, n_paces,
                   expect_pace ? "pace   " : "no pace");
            result(e_start);
        end
    endtask

    // ---------------- stimulus ----------------
    integer s, h, t, i, c0, c1, e0;
    reg [1:0] got_next, exp_next;

    // separate copy of the gate logic for the exhaustive check
    reg  ta, tb, th, tt;
    wire na, nb;
    next_state_logic comb (.A(ta), .B(tb), .H(th), .T(tt), .a_next(na), .b_next(nb));

    initial begin
        $display("");
        $display("======================================================================");
        $display("  PACEMAKER FSM TESTBENCH     (%0d cycles = 1 s, 40 BPM = %0d cycles)",
                 CLK_HZ, BEAT_40);
        $display("======================================================================");

        // ---- 1. Gate logic vs. state table, all valid states and inputs ----
        $display("");
        $display("[1] Next-state logic vs. state table");
        $display("      State  H T  ->  Next   Expected   Result");
        $display("      -----  ---      -----  --------   ------");
        for (s = 0; s < 3; s = s + 1)
            for (h = 0; h < 2; h = h + 1)
                for (t = 0; t < 2; t = t + 1) begin
                    {ta, tb} = s[1:0]; th = h; tt = t;
                    #1;
                    got_next = {na, nb};
                    exp_next = expected_next(s[1:0], h[0], t[0]);
                    check(got_next === exp_next);
                    $display("      %s  %0d %0d  ->  %s  %s      %s",
                             name(s[1:0]), h, t, name(got_next), name(exp_next),
                             (got_next === exp_next) ? "PASS" : "FAIL");
                end

        // ---- 2. Reset: RESET -> WAIT ----
        $display("");
        e0 = errors;
        repeat (2) tick;
        rst = 0;
        check({A,B} === S_RESET && R === 1'b1);
        tick;
        check({A,B} === S_WAIT);
        $write("[2] Reset: RESET with R=1, then WAIT ............................. ");
        result(e0);

        // ---- 3. No heartbeat: must pace at a steady rate ----
        e0 = errors;
        wait_pace(c0);
        for (i = 0; i < 3; i = i + 1) begin
            wait_pace(c1);
            check(c1 - c0 == LIMIT + 3);
            c0 = c1;
        end
        $write("[3] No heartbeat: pace every %0d cycles (%0d.%0d BPM), 3 times ...... ",
               LIMIT + 3, CLK_HZ*60/(LIMIT+3), (CLK_HZ*600/(LIMIT+3))%10);
        result(e0);

        // ---- 4. Heartbeat and timer in the same cycle: heartbeat wins ----
        e0 = errors;
        beats(100, 1);                       // resync on a heartbeat
        wait (T === 1 && {A,B} === S_WAIT);
        #1;
        H = 1; tick; H = 0;
        check({A,B} === S_RESET);
        tick;
        check({A,B} === S_WAIT);
        $write("[4] Heartbeat and timer in the same cycle -> RESET ............... ");
        result(e0);

        // ---- 5. Heart rate scenarios ----
        $display("");
        $display("[5] Heart-rate scenarios (6 beats each)");
        $display("      Beat interval   Heart rate   Paces   Expected   Result");
        $display("      -------------   ----------   -----   --------   ------");
        beats(100, 1);                       // resync
        scenario(100, 0);    // 60 BPM   : never pace
        scenario(150, 0);    // 40 BPM   : at the limit, never pace
        scenario(151, 1);    // ~39.7 BPM: pace
        scenario(200, 1);    // 30 BPM   : pace
        scenario(100, 0);    // back to 60 BPM: pacing stops

        // ---- 6. Random beat spacing, checked every cycle ----
        $display("");
        e0 = errors;
        repeat (50) beats(60 + ($urandom % 160), 1);
        $write("[6] Random beat spacing (50 beats), checked every cycle .......... ");
        result(e0);

        // ---- Summary ----
        $display("");
        $display("======================================================================");
        if (errors == 0)
            $display("  RESULT: ALL TESTS PASSED    (%0d checks, %0d paces delivered)",
                     checks, paces);
        else
            $display("  RESULT: %0d OF %0d CHECKS FAILED", errors, checks);
        $display("======================================================================");
        $display("");
        $finish;
    end

    initial begin
        $dumpfile("pacemaker.vcd");
        $dumpvars(0, pacemaker_tb);
    end
endmodule