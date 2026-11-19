// pacemaker.v
// 3-state Moore machine, state = {A,B}
//   RESET 00 : R=1 (resets timer), H=1 -> RESET, H=0 -> WAIT
//   WAIT  01 : H=1 -> RESET, H=0&T=0 -> WAIT, H=0&T=1 -> PACE
//   PACE  10 : P=1, always -> RESET
//   11       : unused
//
//   A_next = B & ~H & T
//   B_next = ~(A | H | B&T)
//   R      = ~(A | B)
//   P      = A

// Next-state logic, NAND2/NOR2 and one inverter
module next_state_logic (
    input  A, B, H, T,
    output a_next, b_next
);
    wire nbt, anh, g4;

    nand g1 (nbt, B, T);         // ~(B & T)
    nor  g2 (a_next, H, nbt);    // ~H & B & T
    nor  g3 (anh, A, H);         // ~(A | H)
    nand g4i (g4, nbt, anh);     // ~(~(B&T) & ~(A|H)) = A | H | B&T
    not  n1 (b_next, g4);        // ~(A | H | B&T)
endmodule

module pacemaker (
    input  clk, rst,   // synchronous reset to RESET (00)
    input  H, T,
    output R, P,
    output A, B        // current state, exposed for testing
);
    wire a_next, b_next;
    reg  a_q, b_q;

    next_state_logic nsl (
        .A(a_q), .B(b_q), .H(H), .T(T),
        .a_next(a_next), .b_next(b_next)
    );

    always @(posedge clk) begin
        if (rst) begin
            a_q <= 1'b0;
            b_q <= 1'b0;
        end else begin
            a_q <= a_next;
            b_q <= b_next;
        end
    end

    assign A = a_q;
    assign B = b_q;

    nor gR (R, a_q, b_q);   // R = 1 only in 00
    assign P = a_q;         // P = 1 only in 10 (11 is unreachable)
endmodule