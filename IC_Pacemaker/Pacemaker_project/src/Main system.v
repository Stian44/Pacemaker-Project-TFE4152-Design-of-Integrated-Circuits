	  


module Pacemaker_FSM (
	input clk,
	input H,
	input reset, 				//need an external reset for when booting the system up
	
	output reg P,
	output reg R,
	output reg ERROR
);

	reg	A, B;	 			//MSB and LSB
	wire Next_A, Next_B;  	   	//Next_MSB and Next_LSB
	wire w_T;
	
	
	ripple_counter Input_T ( 	//ripple counter for input T
		.clk(clk),
		.reset(R),
		
		.Q(),
		.T(w_T)				
	);
	
	
	Digital_Gates next_state_logic (
        .H(H),
        .T(w_T),
        .A(A),
        .B(B), 
		
        .MSB(Next_A),   		//Feeds into the register
        .LSB(Next_B)   		//Feeds into the register
    );
	
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin		//Instantiation of system
			A <= 1'b0;
			B <= 1'b0;
		end
		else begin
		   A <= Next_A;
		   B <= Next_B;
		end
	end	   
	
	always @(*) begin
		
		P = 1'b0;
		R = 1'b0;
		ERROR = 1'b0;
		
		if(A == 1'b0 && B == 1'b0) begin
			R = 1'b1;
		end			
		else if(A == 1'b1 && B == 1'b0) begin
			P = 1'b1;
		end			
		else if(A == 1'b1 && B == 1'b1) begin
			R = 1'b1;
			ERROR = 1'b1;
		end
	end
endmodule		 
	
