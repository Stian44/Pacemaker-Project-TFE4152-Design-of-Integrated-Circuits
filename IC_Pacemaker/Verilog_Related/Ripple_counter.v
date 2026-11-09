
module ripple_counter (
	input clk,
	input reset,
	
	output [0:9] Q, 			//brukes som output for testbench
	output T
);			

	wire [9:0] Q_bar;
	wire T_bar;

	genvar i;				//for my for-loop

	d_flipflop flipflop0 (  
		.clk   (clk),
		.D     (Q_bar[0]),
		.reset (reset),
		.Q	   (Q[0]),
		.Q_bar (Q_bar[0])						
	);	  					//first flip-flop
					  		
	
	generate
		for	(i = 1; i < 10; i = i + 1) begin : gen_ripple_counter
			d_flipflop flipflops (
			.clk	(Q_bar[i-1]),
			.D		(Q_bar[i]),
			.reset	(reset),
			.Q		(Q[i]),
			.Q_bar	(Q_bar[i])
			);
		end
	endgenerate
	
	nand (T_bar, Q[8], Q[9]);
	not	 (T, T_bar);	  
	
endmodule	

	
		
		
		
		
		