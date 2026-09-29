`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// BL1A TARGET protect logic: based on document TNFSUM.doc,T1SUM.doc, T2SUM.doc;	    
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// Nov.25,2019: Modified based on TNF_logic.v

// Name-channel Mapping: 
// Note: channel is the Analog current input channel of 1039 module, TH_Index = Read_back index
//      
//Tabel 1: common for all T1,T2,TNF
// TH_Index channel Signal  Threshold    Signal_meaning     Notes
// readback_Index
// 0        0       U_value     U_th                            external input
// 1        1       D_value     D_th            
// 2        2       L_value     L_th            
// 3        3       R_value     R_th            
// 4        4       Halo_value  Halo_th         
// 5        5       Den_value   Den_th          
// 6        6       Tot_value   Tot_th                          external input
// 7        7       HV_value    HV_th          ProtectMonitorHV external input                      
// 8                absLR_value LMR_th         |L-R|            calculated
// 9                absUD_value UMD_th         |U-D|            calculated
// 10               absDT_value DMT_th         |D-T|            calculated
// 11               SOT_value   SOT_th         Sum/Total        calculated     
// 12               TMS_value   TMS_th         Total-Sum        calculated 
            
// 13               T30_value  T30_th        only for TNF     added on Nov.13,2019
// 14               T80_value  T80_th        only for TNF     added on Nov.13,2019
                         
               
//Tabel 2: Input signal to Interlock logic 
//!!! Specific to T2  !!!
//Analog_in_channel = Mask_Index
// Mask_Index   Signal    Mask_T2(default) Digi_channel  
// 0             U_OK       1                      
// 1             D_OK       1             
// 2             L_OK       1
// 3             R_OK       1
// 4             HALO_OK     1 
// 5             HV_OK    1
// 6             TMS_OK      1 
// 7             VAC_OK   1              0

//Tabel 3: Mapping Backpanel channel to logic channel, using this table when connect physical signal cables.
//backpannel lables:
//Aanalog input: starting from left when facing to the backpanel: ch0, 1,2,to 7
//Relay output: starting from left, top row: ch0,1,2,3, bottom row: ch4,5,6,7
//Digi input: same as above Relay output, top row: ch0,1,2,3, bot row: ch4,5,6,7

//!!! Specific to T2  !!!

//Note: Analog input channel see table 1.
//The following table's 1st colomn is register index = backpanel channel number.
//It has been already mapped in top module to correct GPIO pins.
//All other channels are not defined.

//Digi-in PCBch   Signal    
// 0      3   	VAC_OK     

//Realy   PCBch   Signal    
// 0        3     T2_SUMMARY    
// 1        5     PROT_HV_En    
// 2        7     SEM_HV_En      


//////////////////////////////////////////////////////////////////////////////////
module T2_logic(
   input clk,   
	input rst,
	input [7:0] digi_in, //8 channel digital input
	input [15:0] mask,
	input clear_trip, //change status to indicate the action
	input clear_tripcnt, //
	
	input [ADC_BIT_WIDTH-1:0] analog_in[7:0], //8 analog input,signed 16 bit, in unit of mV. 
	input [ADC_BIT_WIDTH-1:0] thresh[15:0], //16 trip threshold, signed 16 bit,in unit of mV;
	
	output [ADC_BIT_WIDTH-1:0] readback[15:0], //16 analog values for read back, signed 16 bit, in unit of mV;	
	output [31:0] last_trip_bit, //Relay[0] use 16MSB, Relay[1] ~ [7] each use 2 bits.
	output [31:0] status,  //legacy: 32 bit status 
	output [7:0] relay,
	output fault,
   output [7:0] relay_cnt[7:0] 

    );

parameter  	ADC_BIT_WIDTH = 16;

//Scale the signal voltage to equal the PIE amplifier gain of T2 protect: 
//based on A-20033 and Mini-PCA gain= 1uA/V (range = 10uA)
//scale factor: U,D,L,R = 1/0.8=1.25; Total = 0.25; Halo = 5;
wire signed [ADC_BIT_WIDTH-1:0] U = analog_in[0];
wire signed [ADC_BIT_WIDTH-1:0] D = analog_in[1];
wire signed [ADC_BIT_WIDTH-1:0] L = analog_in[2];
wire signed [ADC_BIT_WIDTH-1:0] R = analog_in[3];
wire signed [ADC_BIT_WIDTH-1:0] Halo = analog_in[4];
//wire signed [ADC_BIT_WIDTH-1:0] Den = analog_in[5];
wire signed [ADC_BIT_WIDTH-1:0] Tot = analog_in[6];
wire signed [ADC_BIT_WIDTH-1:0] HV = analog_in[7]; 

wire signed [ADC_BIT_WIDTH-1:0] Scaled_U = U + (U >>> 2); //*1.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_D = D + (D >>> 2); //*1.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_L = L + (L >>> 2); //*1.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_R = R + (R >>> 2); //*1.25

wire signed [ADC_BIT_WIDTH-1:0] Scaled_SUM = (D + U + L + R) >>> 2; // divided by 4, scaled to be the same unit as Tota

wire signed [ADC_BIT_WIDTH-1:0] Scaled_Halo = (Halo <<< 2) + Halo; //*5
wire signed [ADC_BIT_WIDTH-1:0] Scaled_Tot = (Tot >>> 2); //* 0.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_HV = HV; 


//Assign monitor ananolg signal according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire signed [ADC_BIT_WIDTH-1:0] U_value = Scaled_U;
wire signed [ADC_BIT_WIDTH-1:0] D_value = Scaled_D;
wire signed [ADC_BIT_WIDTH-1:0] L_value = Scaled_L;
wire signed [ADC_BIT_WIDTH-1:0] R_value = Scaled_R;
wire signed [ADC_BIT_WIDTH-1:0] Halo_value = Scaled_Halo;

wire signed [ADC_BIT_WIDTH-1:0] Tot_value = Scaled_Tot;
wire signed [ADC_BIT_WIDTH-1:0] HV_value = Scaled_HV; 

wire signed [ADC_BIT_WIDTH-1:0] SUM_value = Scaled_SUM; 

//Assign threshold according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire [ADC_BIT_WIDTH-1:0] U_th = thresh[0];
wire [ADC_BIT_WIDTH-1:0] D_th = thresh[1];
wire [ADC_BIT_WIDTH-1:0] L_th = thresh[2];
wire [ADC_BIT_WIDTH-1:0] R_th = thresh[3];
wire [ADC_BIT_WIDTH-1:0] Halo_th = thresh[4];
//wire [ADC_BIT_WIDTH-1:0] Den_th = thresh[5];
//wire [ADC_BIT_WIDTH-1:0] Tot_th = thresh[6];
wire [ADC_BIT_WIDTH-1:0] HV_th = thresh[7];
//wire [ADC_BIT_WIDTH-1:0] LMR_th = thresh[8];
//wire [ADC_BIT_WIDTH-1:0] UMD_th = thresh[9];
//wire [ADC_BIT_WIDTH-1:0] DMT_th = thresh[10];
//wire [ADC_BIT_WIDTH-1:0] SOT_th = thresh[11];
wire [ADC_BIT_WIDTH-1:0] TMS_th = thresh[12];
 
//Assign read_back according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
assign readback[0] = U_value;
assign readback[1] = D_value;
assign readback[2] = L_value;
assign readback[3] = R_value;
assign readback[4] = Halo_value;
//assign readback[5] = Den_value;
assign readback[6] = Tot_value;
assign readback[7] = HV_value;
//assign readback[8] = absLR_value;
//assign readback[9] = absUD_value;
//assign readback[10] = absDT_value;
assign readback[11] = SUM_value;
assign readback[12] = TMS_value;


////////////////////////////////////////////////////////

//Assign digital input signal according to Table 2 above:
wire VAC_OK = digi_in[0];

//when optical board lost power, all digi-in becomes "1", 
//thus the ununsed input could be monitored as watch dog signal.
wire WD = (~digi_in[4]) & (~digi_in[5]) & (~digi_in[6]) & (~digi_in[7]);
  
wire L_OK = L_value[15]? 1'b1 : L_value < L_th;
wire R_OK = R_value[15]? 1'b1 : R_value < R_th;
wire D_OK = D_value[15]? 1'b1 : D_value < D_th;
wire U_OK = U_value[15]? 1'b1 : U_value < U_th;

wire signed [ADC_BIT_WIDTH-1:0] TMS_value = Tot_value - SUM_value;

wire TMS_OK = TMS_value[15]? 1'b1 : TMS_value < TMS_th;

wire HALO_OK = Halo_value[15]? 1'b1 : Halo_value < Halo_th;
wire HV_OK = HV_value[15]? 1'b0 : (HV_value > HV_th); //08012019SL: only use the lower limit.


////////////////////////////

wire Umask = ~mask[0];
wire Dmask = ~mask[1];
wire Lmask = ~mask[2];
wire Rmask = ~mask[3];
wire HALOmask = ~mask[4];
wire HVmask = ~mask[5];
wire TMSmask = ~mask[6];
wire VACmask = ~mask[7];

//output relay contacts
wire T2_SUMMARY = WD & (L_OK|Lmask) & (R_OK|Rmask) & (D_OK|Dmask) & (U_OK|Umask) & (TMS_OK|TMSmask) & (HALO_OK|HALOmask) & (HV_OK|HVmask) & (VAC_OK|VACmask); 
wire Prot_HV_En = VAC_OK|VACmask;
wire Sem_HV_En = VAC_OK|VACmask;

wire not_fault = relay[0]; //ony T2_Summary is regarded as trip
assign fault = ~not_fault;

wire [7:0] trip_bit = ~relay;

  
trip_log_T2 trip_log_ins(
   .clk(clk),   
	.rst(rst),

	.Umask(Umask),
	.Dmask(Dmask),
	.Lmask(Lmask),
	.Rmask(Rmask),
	
	.HALOmask(HALOmask),
	.HVmask(HVmask),
	.TMSmask(TMSmask),
	.VACmask(VACmask),

	.T2_SUMMARY(T2_SUMMARY),
	.trip_bit(trip_bit),
	.status(status),
	.fault(fault), 
  
   .last_trip_reg(last_trip_bit)

    );
	 
//----------------------------------------------------------------------

wire [7:0] relay_in;
assign relay_in[0] = T2_SUMMARY; 
assign relay_in[1] = Prot_HV_En;
assign relay_in[2] = Sem_HV_En;
assign relay_in[3] = 1'b0; //not in use, set to "0" to save power
assign relay_in[4] = 1'b0;
assign relay_in[5] = 1'b0;
assign relay_in[6] = 1'b0;
assign relay_in[7] = 1'b0; //not in use, set to "0" to save power
						
assign relay[7:3] = 5'b0;

assign relay_cnt[3] = 0;
assign relay_cnt[4] = 0;
assign relay_cnt[5] = 0;
assign relay_cnt[6] = 0;
assign relay_cnt[7] = 0;

//trip 0,1,2						
genvar i;
generate 
for (i = 0; i < 3 ; i = i + 1) 
	begin: trip_unit_group1
		trip_unit trip_unit_ins1(
			.clk(clk),   
			.rst(rst),
			.data(relay_in[i]),
			.clear_trip(clear_trip), 
			.state_bits(),	
			.trip_cnt(relay_cnt[i]),
			.relay_reg(relay[i])
    );
		
  	end
endgenerate 

//----------------------------------------------------------------------
assign status[0] = WD;  
assign status[1] = L_OK;
assign status[2] = R_OK;  
assign status[3] = D_OK;  
assign status[4] = U_OK;  
assign status[5] = TMS_OK; 
assign status[6] = HALO_OK;  
assign status[7] = HV_OK;  
assign status[8] = VAC_OK;  
assign status[9] = T2_SUMMARY; //T1SUM_OK;  
assign status[10] = 1'b0; 
assign status[11] = 1'b0; 
assign status[16:12] = 5'b00000; //not in use
assign status[17] = relay[0];
assign status[18] = relay[1];
assign status[19] = relay[2];
assign status[20] = relay[3]; 
assign status[21] = relay[4];
assign status[22] = relay[5];
assign status[23] = relay[6];
assign status[24] = relay[7];
assign status[30:25] = 6'b000000; ////not in use
assign status[31] = not_fault;

endmodule
