module Digital_Gates(
	input H,
	input T,
	input A,
	input B,
	
	output MSB,
	output LSB,
	output ERROR,
	output P,
	output R
	);  
	
	wire nH, nA;	   
	wire m1, m2, m3, m4, m5;
	
	//our_inverter inv_H(nH, H); 
	our_inverter inverternA(nA, A);
	
	//MSB
	our_xor xor_AB(m1, A, B);	
	our_inverter inverter_m1(m2, m1);
	our_nor nor_m2H(m3, m2, H);
	
	//Kan byttes ut med nand?
	our_nor norTA(m4, A, T);
	our_inverter inverterM5(m5, m4);
	
	our_nand nandM5M3(m6, m3, m5);
	our_inverter inverterM6(MSB, m6);  
	
	//LSB	 
	wire l1, l2;
	
	our_3nand nand3_ABT(l1, nA, B, T);
	our_inverter inverterl1(l2, l1);
	our_nor nor_l2H(LSB, H, l2);
	
endmodule