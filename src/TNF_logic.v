`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// BL1A TARGET TNF protect logic: TNFSUM.doc, A-20036(rev10), A-20038(rev11);	    
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified:
// Nov.13,2019: Add most functions from T1_logic.v;


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
                     
//Tabel 2: Specific to TNF
// Mask_Index   Signal    Mask_TNF(default) 
// 0             absLR_OK    1             
// 1             absDU_OK    1             
// 2             absDT_OK    1
// 3             Halo_OK     1
// 4             T30uA_OK   1 
// 5             T80uA_OK   1
// 6             HV_OK       1 
// 7             Prof_OK     1              
// 8             Prot_OK     1                         
// 9             TRIMAC_OK   1                
// 10            VAC_OK      1              

//Tabel 3: Mapping Backpanel channel to logic channel, using this table when connect physical signal cables.
//backpannel lables:
//Aanalog input: starting from left when facing to the backpanel: ch0, 1,2,to 7
//Relay output: starting from left, top row: ch0,1,2,3, bottom row: ch4,5,6,7
//Digi input: same as above Relay output, top row: ch0,1,2,3, bot row: ch4,5,6,7

//!!! Specific to TNF  !!!

//Note: Analog input channel see table 1.
//The following table's 1st colomn is register index = backpanel channel number.
//It has been already mapped in top module to correct GPIO pins.

//Digi-in PCBch   Signal    
// 0      3   	Prof_OK     
// 1      4   	Prot_OK      
// 2      1   	TRIMAC_OK      
// 3      2   	VAC_OK  

// 4      7   	Not defined   
// 5      8   	Not defined   
// 6      5   	Not defined   
// 7      6   	Not defined   

//Realy   PCBch   Signal    
// 0        3     TNF_SUMMARY    
// 1        5     PROF_HV_En    
// 2        7     PROT_HV_En      
// 3        1     500MEV_TRIP   
 
// 4        4     Not defined  
// 5        6     Not defined  
// 6        8     Not defined 
// 7        2     Not defined

//////////////////////////////////////////////////////////////////////////////////
module TNF_logic(
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

//Scale the signal voltage to equal the PIE amplifier gain of TNF protect: 
//based on A-20036 and Mini-PCA gain= 1uA/V
//scale factor: U,D,L,R = 1; Den,Total = 0.25; Halo = 2.5;
wire signed [ADC_BIT_WIDTH-1:0] U = analog_in[0];
wire signed [ADC_BIT_WIDTH-1:0] D = analog_in[1];
wire signed [ADC_BIT_WIDTH-1:0] L = analog_in[2];
wire signed [ADC_BIT_WIDTH-1:0] R = analog_in[3];
wire signed [ADC_BIT_WIDTH-1:0] Halo = analog_in[4];
wire signed [ADC_BIT_WIDTH-1:0] Den = analog_in[5];
wire signed [ADC_BIT_WIDTH-1:0] Tot = analog_in[6];
wire signed [ADC_BIT_WIDTH-1:0] HV = analog_in[7]; 

//wire signed [15:0] SUM_value = (D + U) >>> 1; //0524_2019SL, scaled to be the same unit as Total

wire signed [ADC_BIT_WIDTH-1:0] Scaled_U = U;
wire signed [ADC_BIT_WIDTH-1:0] Scaled_D = D;
wire signed [ADC_BIT_WIDTH-1:0] Scaled_L = L;
wire signed [ADC_BIT_WIDTH-1:0] Scaled_R = R;

wire signed [ADC_BIT_WIDTH-1:0] Scaled_Halo = (Halo <<< 1) + (Halo >>> 1); //times 2.5
wire signed [ADC_BIT_WIDTH-1:0] Scaled_Den = (Den >>> 2); //times 0.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_Tot = (Tot >>> 2); //times 0.25
wire signed [ADC_BIT_WIDTH-1:0] Scaled_HV = HV; 



//Assign monitor ananolg signal according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire signed [ADC_BIT_WIDTH-1:0] U_value = Scaled_U;
wire signed [ADC_BIT_WIDTH-1:0] D_value = Scaled_D;
wire signed [ADC_BIT_WIDTH-1:0] L_value = Scaled_L;
wire signed [ADC_BIT_WIDTH-1:0] R_value = Scaled_R;
wire signed [ADC_BIT_WIDTH-1:0] Halo_value = Scaled_Halo;
wire signed [ADC_BIT_WIDTH-1:0] Den_value = Scaled_Den;
wire signed [ADC_BIT_WIDTH-1:0] Tot_value = Scaled_Tot;
wire signed [ADC_BIT_WIDTH-1:0] HV_value = Scaled_HV; 

//Assign threshold according to Table 1 above:
//!!! common for all T1,T2,TNF !!!

wire [ADC_BIT_WIDTH-1:0] Halo_th = thresh[4];
//wire [ADC_BIT_WIDTH-1:0] Den_th = thresh[5]; //not in use
//wire [ADC_BIT_WIDTH-1:0] Tot_th = thresh[6]; //not in use
wire [ADC_BIT_WIDTH-1:0] HV_th = thresh[7];
wire [ADC_BIT_WIDTH-1:0] LMR_th = thresh[8];
wire [ADC_BIT_WIDTH-1:0] UMD_th = thresh[9];
wire [ADC_BIT_WIDTH-1:0] DMT_th = thresh[10];

wire [ADC_BIT_WIDTH-1:0] T30_th = thresh[13]; // i.e. 1AM11 profile current
wire [ADC_BIT_WIDTH-1:0] T80_th = thresh[14]; //i.e. Total 

//wire [ADC_BIT_WIDTH-1:0] HV_th_half = {HV_th[15],HV_th[15:1]};
 
//Assign read_back according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
assign readback[0] = U_value;
assign readback[1] = D_value;
assign readback[2] = L_value;
assign readback[3] = R_value;

assign readback[4] = Halo_value;
assign readback[5] = Den_value;
assign readback[6] = Tot_value;
assign readback[7] = HV_value;

assign readback[8] = absLR_value;
assign readback[9] = absUD_value;
assign readback[10] = absDT_value;

assign readback[11] = 0;
assign readback[12] = 0;
assign readback[13] = 0;

//Assign digital input signal according to Table 2 above:
wire Prof_OK = digi_in[0];
wire Prot_OK = digi_in[1];
wire TRIMAC_OK = digi_in[2];
wire VAC_OK = digi_in[3];

////////////////////////////////////////////////////////
wire signed [15:0] L_R = L_value - R_value;
wire signed [15:0] absLR_value = L_R[15]? {1'b0,~L_R} : {1'b0,L_R};
		
wire signed [15:0] U_D = U_value-D_value;					
wire signed [15:0] absUD_value = U_D[15]? {1'b0,~U_D} : {1'b0,U_D};

wire signed [15:0] D_T = Den_value-Tot_value;		
wire signed [15:0] absDT_value = D_T[15]? {1'b0,~D_T} : {1'b0,D_T};

wire absLR_OK  = absLR_value < LMR_th;
wire absDU_OK  = absUD_value < UMD_th;						
wire absDT_OK  = absDT_value < DMT_th;

//when optical board lost power, all digi-in becomes "1", 
//thus the ununsed input could be monitored as watch dog signal.
wire WD = (~digi_in[4]) & (~digi_in[5]) & (~digi_in[6]) & (~digi_in[7]);
  
wire Halo_OK = Halo_value[15]? 1'b1 : Halo_value < Halo_th;
wire T30uA_OK = Tot_value[15]? 1'b1 : Tot_value < T30_th;
wire T80uA_OK = Tot_value[15]? 1'b1 : Tot_value < T80_th;
wire HV_OK = HV_value[15]? 1'b0 : (HV_value > HV_th); //08012019SL: only use the lower limit.
   
wire absLR_mask = ~mask[0];
wire absDU_mask = ~mask[1];
wire absDT_mask = ~mask[2];
wire Halo_mask = ~mask[3];
wire T30uA_mask = ~mask[4];
wire T80uA_mask = ~mask[5];
wire HV_mask = ~mask[6];
wire Prof_mask = ~mask[7];
wire Prot_mask = ~mask[8];
wire TRIMAC_mask = ~mask[9];
wire VAC_mask = ~mask[10];

//Logic output calculation:
wire TNF_SUM1 = WD & (absLR_OK|absLR_mask) & (absDU_OK|absDU_mask) & (absDT_OK|absDT_mask) & (Halo_OK|Halo_mask); 
wire TNF_SUM2 = (T80uA_OK|T80uA_mask) & (HV_OK|HV_mask) & (TRIMAC_OK|TRIMAC_mask) & (VAC_OK|VAC_mask); 
wire TNF_SUM3 = (T30uA_OK|T30uA_mask) | ~(Prof_OK|Prof_mask);
wire TNF_SUM4 = (Prof_OK|Prof_mask) ^ (Prot_OK|Prot_mask);  

wire TNF_SUMMARY = TNF_SUM1 & TNF_SUM2 & TNF_SUM3 & TNF_SUM4;
wire Prof_HV_En = Prof_OK;
wire Prot_HV_En = VAC_OK;  //Protect monitor has two, so HV should be enable no mater its position
wire DT_en = absDT_OK;
wire Posi_OK = TNF_SUM4; //Either Profile or Protect monitor to be at IN position


// trip register log

//only relay output 0,1,2 are in use, 3 might not.

wire not_fault = relay[0]; //ony TNF_Summary is regarded as trip, since prof position would be not OK normally.
assign fault = ~not_fault;


wire [7:0] trip_bit = ~relay;

trip_log_TNF trip_log_ins(
   .clk(clk),   
	.rst(rst),
	
	.absLR_mask(absLR_mask),
	.absDU_mask(absDU_mask),
	.absDT_mask(absDT_mask),
	.Halo_mask(Halo_mask),
	.T30uA_mask(T30uA_mask),
	.T80uA_mask(T80uA_mask),
	.HV_mask(HV_mask),
	.Prof_mask(Prof_mask),
	.Prot_mask(Prot_mask),
	.TRIMAC_mask(TRIMAC_mask),
	.VAC_mask(VAC_mask),

	.TNF_SUMMARY(TNF_SUMMARY),
	.trip_bit(trip_bit),
	.status(status),
	.fault(fault), 
  
   .last_trip_reg(last_trip_bit)

    );
	 
wire [7:0] relay_in;
assign relay_in[0] = TNF_SUMMARY; //goes to T1 protect 1039
assign relay_in[1] = Prof_HV_En;
assign relay_in[2] = Prot_HV_En;
assign relay_in[3] = DT_en; //might not be in use?

assign relay_in[4] = 1'b0; //not in use, set to "0" to save power
assign relay_in[5] = 1'b0; //not in use, set to "0" to save power
assign relay_in[6] = 1'b0; //not in use, set to "0" to save power
assign relay_in[7] = 1'b0; //not in use, set to "0" to save power
						
assign relay[4] = 0;
assign relay[5] = 0;
assign relay[6] = 0;
assign relay[7] = 0;

assign relay_cnt[4] = 0;
assign relay_cnt[5] = 0;
assign relay_cnt[6] = 0;
assign relay_cnt[7] = 0;


//trip 0,1,2,3						
genvar i;
generate 
for (i = 0; i < 4 ; i = i + 1) 
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


//----------------------------------------------

assign status[0] = WD;  
assign status[1] = absLR_OK;
assign status[2] = absDU_OK;  
assign status[3] = absDT_OK;  
assign status[4] = Halo_OK;  
assign status[5] = T30uA_OK;  
assign status[6] = T80uA_OK;  
assign status[7] = HV_OK;  

assign status[8] = Prof_OK;  
assign status[9] = Prot_OK;  
assign status[10] = TRIMAC_OK;  
assign status[11] = VAC_OK;  
assign status[12] = TNF_SUMMARY;
assign status[13] = Posi_OK; //
 
assign status[16:14] = 3'b0; //not in use

assign status[17] = relay[0];
assign status[18] = relay[1];
assign status[19] = relay[2];
assign status[20] = relay[3];

assign status[24:21] = 4'b0; //relay[4:7];
assign status[30:25] = 6'b000000; ////not in use
assign status[31] = not_fault;

endmodule
