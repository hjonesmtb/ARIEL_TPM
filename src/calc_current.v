`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
//	    Calculate current i values from ADC input value for 8 channels: 
//              i = ((ADC - 0x8000)/0x8000)*12.288*1000*gain (pA)
//                = (ADC/0x8000 - 1)*12288*gain (pA)
//              V = ((ADC - 0x8000)/0x8000)*12.288*1000 (mV)
//
//      12.288: ADC input range, 0x8000: ADC bin for 0 V input, gain = (10,100,1000,10000) (nA/V)  
//         
//      input: ADC 16 bit straight binary, gain
//      output: I_value, signed number wth 32 bit range, in pA.
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Nov.30,2018
// Modified on May 22,2019: added output:V_value16, signed 16 bit, in unit of mV.
//
//////////////////////////////////////////////////////////////////////////////////
module calc_current(
	input signed [ADC_BIT_WIDTH-1:0] Data_In[7:0],
	input Data_In_Valid, //one clk wide, freq = ADC sampling freq, 1.15 MHz
	input [1:0] gain,
	input [2:0] avg_shift, // number of samples to avg
	input is_aete, // 1 for AETE, 0 for APTW
	input clk,  //35 MHz 
	input rst,

	output signed [31:0] I_avg[7:0], //signed 32 bit, in unit of pA
	output signed [15:0] I_beam[7:0], //signed 16 bit, in unit of mV.
	output reg RDY	// same as Data_In_Valid. ~1.15 MHz
    );

parameter  	ADC_BIT_WIDTH = 16;
parameter  	SF_WIDTH = 32;

//parameter  	K1 = 16'd4; // = 122880,  gain = 10 nA/V, = 12.288*1000/0x8000* gain (pA) 
//parameter  	K2 = 16'd38;// = 1228800,  gain = 100
//parameter  	K3 = 16'd375; // = 12288000,  gain = 1000
//parameter  	K4 = 16'd3750; // = 122880000,/ gain = 10000

//parameter  	KV = 16'd12288;

wire signed [31:0]  	K1 = is_aete? 16'd15 : 16'd150;   // gain = 100 nA/V, =--> 5V*100,000/32768 (pA) 
wire signed [31:0]  	K2 = is_aete? 16'd153 : 16'd1530;   // gain = 1000
wire signed [31:0]  	K3 = is_aete? 16'd1526 : 16'd15260;  // gain = 10000
wire signed [31:0]  	K4 = is_aete? 16'd15260 : 16'd152600; // gain = 100000 

parameter  	KV = 16'd5000; // 5*1000, we will need to divide 0x8000=2**15 later ,i.e. right shift 15 bits.

wire signed [31:0] I_value[7:0];
reg signed [15:0] dataa_sig[7:0];
wire signed [15:0] data_avg1[7:0];
wire signed [15:0] data_aptw[7:0];
wire signed [15:0] data_aete[7:0];

wire signed [15:0] data_filt[7:0];

wire [7:0] d_clk;

wire signed [15:0] k[7:0];
wire signed [31:0] C_value[7:0];
	
//////define states//////////
parameter    state_idle = 0, 
			 state_mul = 1,
			 state_rdy = 2;		 
		 
reg [3:0] state;
reg [3:0] count;

always@ (posedge clk)begin
	if (rst)begin
		count <= 0;
		RDY <= 0;
		state <= state_idle;
	end
	else begin
		case(state)
			state_idle:
			 begin
				if(Data_In_Valid == 1)begin
					dataa_sig[0] <= Data_In[0];
					dataa_sig[1] <= Data_In[1];
					dataa_sig[2] <= Data_In[2];
					dataa_sig[3] <= Data_In[3];
					dataa_sig[4] <= Data_In[4];
					dataa_sig[5] <= Data_In[5];
					dataa_sig[6] <= Data_In[6];
					dataa_sig[7] <= Data_In[7];
					state <= state_mul;
				end		
			 end					
			state_mul: //multiply
				begin
					if (count > 5) begin RDY <= 1; state <= state_rdy; end
				    else count <= count + 1'b1;
				end
			state_rdy:
				begin
					count <= 0;
					RDY <= 0;
					state <= state_idle;
				end	
			default: state <= state_idle;	
				
	    endcase
	end
end

genvar i;
generate 
for (i = 0; i < 8 ; i = i + 1) 
	begin: channel
    assign k[i] = (gain == 2'b00)? K1
					  :(gain == 2'b01)? K2
                 :(gain == 2'b10)? K3
                 :(gain == 2'b11)? K4 
                 :K1;
					  
					  
//	  movavg avg_I(
//				 .signal(I_value[i]), 
//				 .avg_shift(avg_shift),
//				 .clk(clk),    
//				 .data_valid(RDY),
//				 .avg(I_avg[i])
//			);
//			
    CIC #(.width(31)) CIC1 (
		 .clk             (clk),
		 .rst             (0),
		 .data_valid      (Data_In_Valid),
		 .decimation_ratio(8),
		 .d_in            (dataa_sig[i]),
		 .d_out           (data_aete[i]),
		 .d_clk           ()
		);	
	
	
	// changed width from 40 --> 41
    CIC #(.width(41)) CIC2 (
		 .clk             (clk),
		 .rst             (0),
		 .data_valid      (Data_In_Valid),
		 .decimation_ratio(32),
		 .d_in            (dataa_sig[i]),
		 .d_out           (data_avg1[i]),
		 .d_clk           (d_clk[i])
		);	
		
    CIC #(.width(41)) CIC3 (
		 .clk             (clk),
		 .rst             (0),
		 .data_valid      (d_clk[i]),
		 .decimation_ratio(32),
		 .d_in            (data_avg1[i]),
		 .d_out           (data_aptw[i]),
		 .d_clk           ()
		);	
		
		assign I_avg[i] = I_value[i];
	   assign data_filt[i] = is_aete? data_aete[i] : data_aptw[i];
		
		
	 lpm_mul	mul_ch_I (
		.dataa(data_filt[i]),
		.datab(k[i]),
		.result(I_value[i])
		);	 

	 lpm_mul	mul_ch_V (
		.dataa(data_filt[i]),
		.datab(KV),
		.result(C_value[i])
		);	
	 assign I_beam[i] = {C_value[i][31],C_value[i][29:15]}; //divide 0X8000 to convert to mV

	 
	end
endgenerate 

endmodule
