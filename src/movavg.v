/*
Using a 16x boxfilter
*/

module movavg (
    input signed [31:0] signal,  // 32-bit input signal
	 input [2:0] avg_shift,
    input clk,    
	 input data_valid,
	 output reg signed[31:0] avg
);

    reg signed[31:0] signal_1, signal_2, signal_3, signal_4;
	 reg signed[31:0] signal_5, signal_6, signal_7, signal_8;
	 reg signed[31:0] signal_9, signal_10, signal_11, signal_12;
	 reg signed[31:0] signal_13, signal_14, signal_15, signal_16;
	 
	 reg signed[38:0] sum_2, sum_4, sum_8, sum_16; // to hold accumualated sum

    // Always block to update sums and count while gate is high
    always @(posedge clk) begin
		if(data_valid) begin
			signal_1 <= signal;
			signal_2 <= signal_1;
			signal_3 <= signal_2;
			signal_4 <= signal_3;
			signal_5 <= signal_4;
			signal_6 <= signal_5;
			signal_7 <= signal_6;
			signal_8 <= signal_7;
			signal_9 <= signal_8;
			signal_10 <= signal_9;
			signal_11 <= signal_10;
			signal_12 <= signal_11;
			signal_13 <= signal_12;
			signal_14 <= signal_13;
			signal_15 <= signal_14;
			signal_16 <= signal_15;
			
			sum_2  <= (signal_1 + signal_2) >>> 1;
			sum_4  <= (signal_1 + signal_2 + signal_3 + signal_4) >>> 2;
			sum_8  <= (signal_1 + signal_2 + signal_3 + signal_4 + signal_5 + signal_6 + signal_7 + signal_8) >>> 3;
			sum_16 <= (signal_1 + signal_2 + signal_3 + signal_4 + signal_5 + signal_6 + signal_7 + signal_8 + signal_9 + signal_10 + signal_11 + signal_12 + signal_13 + signal_14 + signal_15 + signal_16) >>> 4;
			
			case (avg_shift)
				0: avg <= signal_1;
				1: avg <= sum_2[31:0];
				2: avg <= sum_4[31:0];
				3: avg <= sum_8[31:0];
				4: avg <= sum_16[31:0];
				default:  avg <= signal_1;
			endcase
			
		 end
	end

endmodule
