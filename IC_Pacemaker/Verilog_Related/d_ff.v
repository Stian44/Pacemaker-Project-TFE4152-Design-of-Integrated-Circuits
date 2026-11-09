
module d_flipflop (
	input clk,
	input D,
	input reset,
	
	output Q,
	output Q_bar
);

	// -- wire_declaration --

	wire clk_bar, D_bar;
	wire master_set, master_rst;
	wire master_reset_bar, master_reset;
	wire slave_set, slave_rst;
	wire master_q, master_q_bar;				//defining logic wires of 1 bit

	// -- master_latch --
	
	not  (clk_bar, clk);			   
	not  (D_bar, D);				   			//inverting inputs going into master
	not  (reset_bar, reset);
	
	nand (master_set, D, clk_bar);
	nand (master_rst, D_bar, clk_bar);			//logic reset and set for master 
		
	nand (master_reset_bar, master_rst, reset_bar);
	not  (master_reset, master_reset_bar);		//reset function
	
	nand (master_q, master_set, master_q_bar);
	nand (master_q_bar, master_reset, master_q);	//output Q and Q_bar of master	  
	
	// -- slave_latch --
	
	nand (slave_set, master_q, clk);
	nand (slave_rst, master_q_bar, clk); 		//logic reset and set for slave
		
	nand (Q, slave_set, Q_bar);
	nand (Q_bar, slave_rst, Q);				//output Q and Q_bar of slave  
endmodule