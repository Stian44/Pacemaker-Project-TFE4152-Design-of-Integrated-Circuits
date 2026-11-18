`timescale 1ns / 1ps

module Pacemaker_FSM_tb;
    reg clk;
    reg H;
    reg reset;

    wire P;
    wire R;
    wire ERROR;

    Pacemaker_FSM uut (
        .clk(clk),
        .H(H),
        .reset(reset),
        .P(P),
        .R(R),
        .ERROR(ERROR)
    );
																				
    always #5 clk = ~clk;			// 10ns period
						  
    initial begin
        clk   = 0;
        H     = 0;
        reset = 1;					// Start values, reset = 1 for the bootup

        
        #20;                    
        reset = 0;              	// Reset=0 => state machine should go to 01
        #50;
		
		
        // Simulating when heartbeat happens before timeout (01 -> 00 -> 01)
        repeat (100) @(posedge clk); 
        H = 1;                  
        @(posedge clk);         	 // Waiting one clock cycle for it to detect H 
        #1 H = 0;              
        repeat (10) @(posedge clk);  // Sjekk i bølgeformen at R blinket (tilstand 00) og P forble 0
		
		
		
        // Simulating the scenario where the heart doesn't beat (01 -> 10 -> 11 -> 00)
        repeat (780) @(posedge clk);
		
		
		
        // Simulating the scenario where the pace activates a heartbeat the next cycle (no ERROR)
        repeat (756) @(posedge clk); // Waiting for the cycle T = 1
        @(posedge clk);
        H = 1;                  	 // H = 1 next cycle
        @(posedge clk);
        #1 H = 0;

        #100;
        $finish;
    end

endmodule