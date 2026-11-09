
module tb_ripple_counter;

    reg clk;
    reg reset;

    wire T;
	wire [0:9] Q;

    ripple_counter uut (
        .clk(clk),
        .reset(reset), 
		.Q(Q),
        .T(T)
    );

    always #10 clk = ~clk;	 //20ns period

    initial begin
        clk = 0;			 
        reset = 1;			 //starting by resetting values

        #200; 
        reset = 0;			 //after 200ns, the hold time issue should be no problem

        #16000;				 //768 cycles * 20ns (+200ns) = 15560, which means at 16000ns T should be able to equal 1

        $stop; 				 //stop
    end
endmodule