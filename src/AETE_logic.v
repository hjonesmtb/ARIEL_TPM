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
	input signed [ADC_BIT_WIDTH-1:0] thresh[15:0], //16 trip threshold, signed 16 bit. Units of nA.
	
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
wire signed [DOUBLE_WIDTH-1:0] Halo1 = analog_in[4];
wire signed [DOUBLE_WIDTH-1:0] Total = analog_in[5];

wire signed [DOUBLE_WIDTH-1:0] HV = analog_in[7]; 

wire signed [DOUBLE_WIDTH-1:0] SUM_value = (U + D + L + R);

wire signed [DOUBLE_WIDTH-1:0] Scaled_U = U;
wire signed [DOUBLE_WIDTH-1:0] Scaled_D = D;
wire signed [DOUBLE_WIDTH-1:0] Scaled_L = L;
wire signed [DOUBLE_WIDTH-1:0] Scaled_R = R;

wire signed [DOUBLE_WIDTH-1:0] Scaled_Halo1 = Halo1; 
wire signed [DOUBLE_WIDTH-1:0] Scaled_Total = Total; 
wire signed [DOUBLE_WIDTH-1:0] SUM_ratio; // = Sum/Total * 100
wire signed [DOUBLE_WIDTH-1:0] Density; //   = Halo1/Total *100
wire signed [DOUBLE_WIDTH-1:0] LR_ratio; //  = abs(L-R)/Halo1 *100
wire signed [DOUBLE_WIDTH-1:0] UD_ratio; //  = abs(U-D)/Halo1 *100

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
wire signed [DOUBLE_WIDTH-1:0] U_th = (thresh[0] * 1000);// nA
wire signed [DOUBLE_WIDTH-1:0] D_th = (thresh[1] * 1000);//  nA
wire signed [DOUBLE_WIDTH-1:0] L_th = (thresh[2] * 1000);//  nA
wire signed [DOUBLE_WIDTH-1:0] R_th = (thresh[3] * 1000);//  nA
wire signed [DOUBLE_WIDTH-1:0] Halo_th = (thresh[4] * 1000);//  nA
wire signed [DOUBLE_WIDTH-1:0] Total_th = (thresh[5] * 1000);//  nA

wire signed [DOUBLE_WIDTH-1:0] HV_th = (thresh[7] * 1000);//  ?
wire signed [DOUBLE_WIDTH-1:0] HV_th_half = {HV_th[15],HV_th[15:1]};

wire signed [DOUBLE_WIDTH-1:0] abs_LR_th    = (thresh[8]  * 1000);// nA
wire signed [DOUBLE_WIDTH-1:0] abs_UD_th    = (thresh[9]  * 1000);// nA
wire signed [DOUBLE_WIDTH-1:0] LR_ratio_th  = (thresh[10]);			// %
wire signed [DOUBLE_WIDTH-1:0] UD_ratio_th  = (thresh[11]);			// %
wire signed [DOUBLE_WIDTH-1:0] SUM_th       = (thresh[12] * 1000);// nA
wire signed [DOUBLE_WIDTH-1:0] SUM_ratio_th = (thresh[13]);			// %
wire signed [DOUBLE_WIDTH-1:0] Density_th   = (thresh[14]);			// %


 
//Assign read_back according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
assign readback[0] = U;
assign readback[1] = D;
assign readback[2] = L;
assign readback[3] = R;
assign readback[4] = Halo1;
assign readback[5] = Total;

assign readback[7] = HV;

assign readback[8] = abs_LR;
assign readback[9] = abs_UD;
assign readback[10] = LR_ratio;
assign readback[11] = UD_ratio;

assign readback[12] = SUM_value;
assign readback[13] = SUM_ratio;
assign readback[14] = Density;

assign readback[15] = tripped; // for troubleshooting

wire signed [DOUBLE_WIDTH-1:0] abs_U     = (U         < 0) ? -U         : U;
wire signed [DOUBLE_WIDTH-1:0] abs_D     = (D         < 0) ? -D         : D;
wire signed [DOUBLE_WIDTH-1:0] abs_L     = (L         < 0) ? -L         : L;
wire signed [DOUBLE_WIDTH-1:0] abs_R     = (R         < 0) ? -R         : R;
wire signed [DOUBLE_WIDTH-1:0] abs_Halo  = (Halo1     < 0) ? -Halo1     : Halo1;
wire signed [DOUBLE_WIDTH-1:0] abs_Total = (Total     < 0) ? -Total     : Total;
wire signed [DOUBLE_WIDTH-1:0] abs_SUM   = (SUM_value < 0) ? -SUM_value : SUM_value;
wire signed [DOUBLE_WIDTH-1:0] abs_LR 	  = (L > R)? L-R : R-L;
wire signed [DOUBLE_WIDTH-1:0] abs_UD    = (D > U)? D-U : U-D;

wire signed [39:0] abs_LR_x100 = abs_LR*100;
wire signed [39:0] abs_UD_x100 = abs_UD*100;
wire signed [39:0] Halo_x100 = Halo1*100;
wire signed [39:0] Sum_x100 = SUM_value*100;

wire signed [39:0] Halo_x_LR_th, Halo_x_UD_th, Total_x_SR_th, Total_x_Den_th;

lpm_div16	lpm_div16_inst1 (
	.denom ( Scaled_Total ),
	.numer ( Sum_x100 ),
	.quotient ( SUM_ratio ),
	.remain ()
	);

lpm_div16	lpm_div16_inst2 (
	.denom ( Scaled_Total ),
	.numer ( Halo_x100 ),
	.quotient ( Density ),
	.remain ()
	);
	
lpm_div16	lpm_div16_inst3 (
	.denom ( Scaled_Halo1 ),
	.numer ( abs_LR_x100 ),
	.quotient ( LR_ratio ),
	.remain ()
	);
	
lpm_div16	lpm_div16_inst4 (
	.denom ( Scaled_Halo1 ),
	.numer ( abs_UD_x100 ),
	.quotient ( UD_ratio ),
	.remain ()
	);
	
	
lpm_mult_32	lpm_mult_32_inst1 (
	.dataa ( UD_ratio_th ),
	.datab ( abs_Halo ),
	.result ( Halo_x_UD_th )
	);
	
lpm_mult_32	lpm_mult_32_inst2 (
	.dataa ( LR_ratio_th ),
	.datab ( abs_Halo ),
	.result ( Halo_x_LR_th )
	);
	
	
lpm_mult_32	lpm_mult_32_inst3 (
	.dataa ( SUM_ratio_th ),
	.datab ( abs_Total ),
	.result ( Total_x_SR_th )
	);
	
lpm_mult_32	lpm_mult_32_inst4 (
	.dataa ( Density_th ),
	.datab ( abs_Total ),
	.result ( Total_x_Den_th )
	);
	
	
wire Umask = mask[0];
wire Dmask = mask[1];
wire Lmask = mask[2];
wire Rmask = mask[3];
wire HALOmask1 = mask[4];
wire TOTALmask = mask[5];

wire HVmask = mask[7];

wire abs_LR_mask = mask[8];
wire abs_UD_mask = mask[9];
wire LR_ratio_mask = mask[10];
wire UD_ratio_mask = mask[11];

wire SUM_mask = mask[12];
wire SUM_ratio_mask = mask[13];
wire Density_mask = mask[14];


wire [7:0] digi_mask = mask[15:8];				
//------------------------------------	 TRIP LOGIC ----------------------------------		

// remove the Scaled_ prefix on all these...
wire L_OK = (abs_L < L_th);
wire R_OK = (abs_R < R_th);
wire D_OK = (abs_D < D_th) ;
wire U_OK = (abs_U < U_th);
wire HALO_OK1 = (abs_Halo < Halo_th) ;
wire TOTAL_OK = (abs_Total < Total_th);

wire abs_LR_OK    = (abs_LR < abs_LR_th);
wire abs_UD_OK    = (abs_UD < abs_UD_th);
wire LR_ratio_OK  = (abs_LR_x100 < Halo_x_LR_th);
wire UD_ratio_OK  = (abs_UD_x100 < Halo_x_UD_th);
wire SUM_OK       = (abs_SUM < SUM_th);
// these are not changed yet -- need to add some more variables as SUM_x100 appears elsewhere
wire SUM_ratio_OK = (Sum_x100 < Total_x_SR_th) & (Sum_x100 > (-Total_x_SR_th));
wire Density_OK   = (Halo_x100 < Total_x_Den_th)     & (Halo_x100 > (-Total_x_Den_th));

wire L_trip = ~L_OK & Lmask;
wire R_trip = ~R_OK & Rmask;
wire U_trip = ~U_OK & Umask;
wire D_trip = ~D_OK & Dmask;
wire HALO_trip1 = ~HALO_OK1 & HALOmask1;
wire TOTAL_trip = ~TOTAL_OK & TOTALmask;

wire abs_LR_trip    = ~abs_LR_OK    & abs_LR_mask;
wire abs_UD_trip    = ~abs_UD_OK    & abs_UD_mask;
wire LR_ratio_trip  = ~LR_ratio_OK  & LR_ratio_mask;
wire UD_ratio_trip  = ~UD_ratio_OK  & UD_ratio_mask;
wire SUM_trip       = ~SUM_OK       & SUM_mask;
wire SUM_ratio_trip = ~SUM_ratio_OK & SUM_ratio_mask;
wire Density_trip   = ~Density_OK   & Density_mask;

wire digi_trip = |(digi_in & digi_mask);
 
wire HV_OK = (Scaled_HV > HV_th); //08012019SL: only use the lower limit.

wire tripped = L_trip | R_trip | U_trip | D_trip | HALO_trip1 | TOTAL_trip
             | abs_LR_trip | abs_UD_trip | LR_ratio_trip | UD_ratio_trip
             | SUM_trip | SUM_ratio_trip | Density_trip;
				 
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
assign status[1] = U_trip;
assign status[2] = D_trip;  
assign status[3] = L_trip;  
assign status[4] = R_trip;  
assign status[5] = HALO_trip1;  
assign status[6] = TOTAL_trip;  
assign status[7] = HV_OK;  
assign status[8]  = abs_LR_trip;
assign status[9]  = abs_UD_trip;
assign status[10] = LR_ratio_trip;
assign status[11] = UD_ratio_trip;
assign status[12] = SUM_trip;
assign status[13] = SUM_ratio_trip;
assign status[14] = Density_trip;

endmodule
