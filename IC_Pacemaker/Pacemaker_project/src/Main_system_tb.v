`timescale 1ns / 1ps

module Pacemaker_FSM_tb;

    // 1. Signaler for å styre og lese av modulen
    reg clk;
    reg H;
    reg reset;

    wire P;
    wire R;
    wire ERROR;

    // 2. Instansier Pacemaker_FSM (Unit Under Test)
    Pacemaker_FSM uut (
        .clk(clk),
        .H(H),
        .reset(reset),
        .P(P),
        .R(R),
        .ERROR(ERROR)
    );

    // 3. Klokkegenerator: Bytter verdi hvert 5. ns (10 ns periode = 100 MHz)
    always #5 clk = ~clk;

    // 4. Testscenarioer
    initial begin
        // Valgfritt: Lagre bølgeform til fil (nyttig for GTKWave / Icarus Verilog)
        $dumpfile("pacemaker_sim.vcd");
        $dumpvars(0, Pacemaker_FSM_tb);

        // Startverdier
        clk   = 0;
        H     = 0;
        reset = 1;

        // --- SCENARIO 1: Oppstart og Reset (Tilstand 00 -> 01) ---
        #20;                    // Hold reset i 2 klokkesykluser
        reset = 0;              // Slipp reset -> maskinen skal gå til 01 (telling)
        #50;

        // --- SCENARIO 2: Normalt hjerteslag før timeout (01 -> 00 -> 01) ---
        repeat (100) @(posedge clk); // Vent 100 klokkesykluser (T er fortsatt 0)
        H = 1;                  // Hjertet slår!
        @(posedge clk);         // Vent én klokkepuls slik at maskinen leser H = 1
        #1 H = 0;               // Senk H igjen
        repeat (10) @(posedge clk);  // Sjekk i bølgeformen at R blinket (tilstand 00) og P forble 0

        // --- SCENARIO 3: Timeout - hjertet slår ikke (01 -> 10 -> 11 -> 00) ---
        // Telleren trenger 768 klokkesykluser før Q[8] og Q[9] begge er 1 (T = 1)
        repeat (780) @(posedge clk);

        // --- SCENARIO 4: Hjertet slår rett etter puls (unngår ERROR) ---
        repeat (768) @(posedge clk); // Vent til akkurat når T blir 1 og P går høy
        @(posedge clk);
        H = 1;                  // Hjertet responderer på pulsen!
        @(posedge clk);
        #1 H = 0;

        #100;
        $finish;                // Avslutt simuleringen
    end

endmodule