module Digital_Gates(
	input H,
	input T,
	input A,
	input B,
	
	output MSB,
	output LSB
	);  
	
	wire nH, nA;	   
	wire m1, m2, m3, m4, m5, m6;
	
	our_inverter inv_H(nH, H); 
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
	
	
	//LSB = !H * (A + !B + !T) = !H * !((!A * B) * T)
	wire l1, l2, l3, l4;

	our_nand     nand_nAB   (l1, nA, B);   // l1 = !(!A * B)
	our_inverter inv_l1     (l2, l1);      // l2 = !A * B
	our_nand     nand_l2T   (l3, l2, T);   // l3 = !(!A * B * T) = A + !B + !T
	our_nand     nand_final (l4, nH, l3);  // l4 = !(!H * (A + !B + !T))
	our_inverter inv_LSB    (LSB, l4);     // LSB = !H * (A + !B + !T)
	
	//LSB	 
	//wire l1, l2, l3, l4;
	
	//our_nand nand_AB(l1, nA, B);      // l1 = !(!A * B)
	//our_inverter inv_l1(l2, l1);      // l2 = !A * B
	//our_nand nand_ABT(l3, l2, T);     // l3 = !(!A * B * T) = A + !B + !T
	//our_nand nand_final(l4, nH, l3);  // l4 = !(!H * (A + !B + !T))
	//our_inverter inv_LSB(LSB, l4);    // LSB = !H * (A + !B + !T)
	
	//our_nand nand_AB(l1, nA, B);
	//our_nand nand_ABT(l2, T, l1);  
	//our_nand l2H(LSB, nH, l2);
endmodule