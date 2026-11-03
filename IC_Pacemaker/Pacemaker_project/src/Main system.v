

module FSM (
	input clk,
	input reset,
	input H
	input T,
	
	output P,
	output R,
	output ERROR,
);

	reg	A, B;	 			//MSB and LSB
	wire Next_A, Next_B;  	//Next_MSB and Next_LSB
	
	assign ERROR  = A & B;
	assign P 	  = A & ~B;
	assign R	  = A & B | ~A & ~B;
	assign Next_A = ~H(A ^ B);
	assign Next_B = ~H(A | ~B | ~T);
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			A <= 1'b0;
			B <= 1'b0;
		end
		else begin
		   A <= Next_A;
		   B <= Next_B;
		end
	end
endmodule