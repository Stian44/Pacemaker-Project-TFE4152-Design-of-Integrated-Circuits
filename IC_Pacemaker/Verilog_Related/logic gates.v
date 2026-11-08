module our_nand(output y, input a, b);
	supply1 vdd;
	supply0 gnd;
	wire mid;
	
	pmos p1(y, vdd, a);
	pmos p2(y, vdd, b);
	
	nmos n1(y, mid, a);
	nmos n2(mid, gnd, b); 	

endmodule 

module our_nor(output y, input a, b);
	supply1 vdd;
	supply0 gnd;
	wire mid;
	
	pmos p1(mid, vdd, a);
	pmos p2(y, mid, b);
	
	nmos n1(y, gnd, a);
	nmos n2(y, gnd, b);

endmodule

module our_inverter(output y, input a);
	supply1 vdd;
	supply0 gnd;
	
	pmos p1(y, vdd, a);
	
	nmos n1(y, gnd, a);

endmodule 

module our_xor(output y, input a, b);
	supply1 vdd;
	supply0 gnd; 
	
	wire an, bn;
	wire m1, m2, m3;		
	
	our_inverter inv_a(an, a);
	our_inverter inv_b(bn, b);
	
	//Pullup
	pmos p1(m1, vdd, a);
	pmos p2(m1, vdd, b);
	pmos p3(y, m1, an);
	pmos p4(y, m1, bb);	 
	
	//Pulldown
	nmos n1(y, m2, a);	   
	nmos n2(y, m3, an);	
	
	nmos n3(m2, gnd, b);
	nmos n4(m3, gnd, bn); 
	
endmodule
	
	
	
	
	
	
	
	
	