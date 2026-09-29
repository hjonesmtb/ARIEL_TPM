`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 


//////////////////////////////////////////////////////////////////////////////////
module AETE_logic(
   input clk,   // 35MHz
	input rst,
	input data_valid,
	input [7:0] digi_in, //8 channel digital input
	input [15:0] mask,
	input clear_trip, //change status to indicate the action
	
	input signed [DOUBLE_WIDTH-1:0] analog_in[7:0], //8 analog input,signed 32 bit
	input signed [ADC_BIT_WIDTH-1:0] thresh[7:0], //16 trip threshold, signed 16 bit
	
	output signed [DOUBLE_WIDTH-1:0] readback[15:0], //16 analog values for read back, signed 32 bit
	output [31:0] status,  //legacy: 32 bit status 
	output reg tripped_reg
    );

parameter  	ADC_BIT_WIDTH = 16;
parameter	DOUBLE_WIDTH = 32;
//parameter  	SF_WIDTH = 32;

//Following added on May 24,2019
//Scale the signal voltage to equal the PIE amplifier gain of T1 protect: 
//based on A-20023 and Mini-PCA gain= 1uA/V
//U,D,L,R = 2.5; Total = 0.5; Halo = 5;
wire signed [DOUBLE_WIDTH-1:0] U = analog_in[0];
wire signed [DOUBLE_WIDTH-1:0] D = analog_in[1];
wire signed [DOUBLE_WIDTH-1:0] L = analog_in[2];
wire signed [DOUBLE_WIDTH-1:0] R = analog_in[3];
wire signed [DOUBLE_WIDTH-1:0] Halo = analog_in[4];

wire signed [DOUBLE_WIDTH-1:0] HV = analog_in[5]; 

wire signed [15:0] SUM_value = (D + U) >>> 1; //0524_2019SL, scaled to be the same unit as Total

wire signed [DOUBLE_WIDTH-1:0] Scaled_U = U;
wire signed [DOUBLE_WIDTH-1:0] Scaled_D = D;
wire signed [DOUBLE_WIDTH-1:0] Scaled_L = L;
wire signed [DOUBLE_WIDTH-1:0] Scaled_R = R;

wire signed [DOUBLE_WIDTH-1:0] Scaled_Halo = Halo; //times 5 
wire signed [DOUBLE_WIDTH-1:0] Scaled_HV = HV; 

//movavg U_avg(
//    .signal(U), 
//	 .avg_shift(avg_shift),
//    .clk(clk),    
//	 .data_valid(data_valid),
//	 .avg(Scaled_U)
//);
//
//movavg D_avg(
//    .signal(D), 
//	 .avg_shift(avg_shift),
//    .clk(clk),    
//	 .data_valid(data_valid),
//	 .avg(Scaled_D)
//);
//
//movavg L_avg(
//    .signal(L), 
//	 .avg_shift(avg_shift),
//    .clk(clk),    
//	 .data_valid(data_valid),
//	 .avg(Scaled_L)
//);
//
//movavg R_avg(
//    .signal(R), 
//	 .avg_shift(avg_shift),
//    .clk(clk),    
//	 .data_valid(data_valid),
//	 .avg(Scaled_R)
//);


//Assign threshold ~ thresh*1000
wire signed [DOUBLE_WIDTH-1:0] U_th = (thresh[0] * 1000);// - (thresh[0] <<< 5);
wire signed [DOUBLE_WIDTH-1:0] D_th = (thresh[1] * 1000);//  - (thresh[1] <<< 5);
wire signed [DOUBLE_WIDTH-1:0] L_th = (thresh[2] * 1000);//  - (thresh[2] <<< 5);
wire signed [DOUBLE_WIDTH-1:0] R_th = (thresh[3] * 1000);//  - (thresh[3] <<< 5);
wire signed [DOUBLE_WIDTH-1:0] Halo_th = (thresh[4] * 1000);//  - (thresh[4] <<< 5);

wire signed [DOUBLE_WIDTH-1:0] HV_th = (thresh[7] * 1000);//  - (thresh[7] <<< 5);
wire signed [DOUBLE_WIDTH-1:0] HV_th_half = {HV_th[15],HV_th[15:1]};
 
//Assign read_back according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
assign readback[0] = Scaled_U;
assign readback[1] = Scaled_D;
assign readback[2] = Scaled_L;
assign readback[3] = Scaled_R;
assign readback[4] = Scaled_Halo;

assign readback[7] = Scaled_HV;
assign readback[8] = absLScaled_R;
assign readback[9] = absUScaled_D;

assign readback[13] = SUM_value;

wire signed [15:0] absLScaled_R = (Scaled_L > Scaled_R)? Scaled_L-Scaled_R
                  : Scaled_R-Scaled_L;					
wire signed [15:0] absUScaled_D = (Scaled_D > Scaled_U)? Scaled_D-Scaled_U
                  : Scaled_U-Scaled_D;

wire Umask = mask[0];
wire Dmask = mask[1];
wire Lmask = mask[2];
wire Rmask = mask[3];
wire HALOmask = mask[4];

wire HVmask = mask[7];

wire [7:0] digi_mask = mask[15:8];				
//------------------------------------	 TRIP LOGIC ----------------------------------		
wire L_OK = (Scaled_L < L_th) & (Scaled_L > (~L_th + 1));
wire R_OK = (Scaled_R < R_th) & (Scaled_R > (~R_th + 1));
wire D_OK = (Scaled_D < D_th) & (Scaled_D > (~D_th + 1));
wire U_OK = (Scaled_U < U_th) & (Scaled_U > (~U_th + 1));
wire HALO_OK = (Scaled_Halo < Halo_th) & (Scaled_Halo > (~Halo_th + 1));

wire L_trip = ~L_OK & Lmask;
wire R_trip = ~R_OK & Rmask;
wire U_trip = ~U_OK & Umask;
wire D_trip = ~D_OK & Dmask;
wire HALO_trip = ~HALO_OK & HALOmask;

wire digi_trip = |(digi_in & digi_mask);
 
wire HV_OK = (Scaled_HV > HV_th); //08012019SL: only use the lower limit.

wire tripped = L_trip | R_trip | U_trip | D_trip | HALO_trip ;
reg clear_trip_resyn1, clear_trip_resyn2;

reg [10:0] tripped_hist;

always@(posedge clk) begin // for synchronous reset
	clear_trip_resyn1 <= clear_trip;
	clear_trip_resyn2 <= clear_trip_resyn1;
	
//	if(data_valid) begin
//		tripped_hist[0] <= tripped;
//		tripped_hist[1] <= tripped_hist[0];
//		tripped_hist[2] <= tripped_hist[1];
//		tripped_hist[3] <= tripped_hist[2];
//		tripped_hist[4] <= tripped_hist[3];
//		tripped_hist[5] <= tripped_hist[4];
//		tripped_hist[6] <= tripped_hist[5];
//		tripped_hist[7] <= tripped_hist[6];
//		tripped_hist[8] <= tripped_hist[7];
//		tripped_hist[9] <= tripped_hist[8];
//		tripped_hist[10] <= tripped_hist[9];
//	end
	
	case({tripped,clear_trip_resyn2})
	  2'b00: tripped_reg <= tripped_reg; // No change
	  2'b01: tripped_reg <= 1'b0; // reset
	  2'b10: tripped_reg <= 1'b1; // set
	  2'b11: tripped_reg <= 1'b1; // Invalid inputs
	endcase
end
//------------------------------------------------------------------------------------

assign status[0] = tripped_reg;  
assign status[1] = L_trip;
assign status[2] = R_trip;  
assign status[3] = D_trip;  
assign status[4] = U_trip;  
assign status[5] = 0;  
assign status[6] = HALO_trip;  
assign status[7] = HV_OK;  

endmodule
