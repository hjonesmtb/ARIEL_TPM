`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// BL1A TARGET protect logic: based on document TNFSUM.doc,T1SUM.doc, T2SUM.doc;	    
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: 
// January 27,2019, add trip count for each trip (relay output), 
//                and last trip source register.  
// May 2, 2019: Add readback[13]= SUM_value ;
// May 22, 2019: changed to work with voltage instead of current values;
// Aug.1,2019: changed HV-th as the lower limit, remove the higher limit on HV_OK, not compile yet.

// Erwin: 
// 1.) each relay output needs a trip count
// 2.) Last trip condition: a snap of all the condition(OK signal) saved in the data packet 
// 3.) use the name "defeat" to replace "mask"

// Name-channel Mapping: 
// Note: channel is the Analog current input channel of 1039 module, TH_Index = Read_back index
//      
//Tabel 1: common for all T1,T2,TNF
// TH_Index channel Signal  Threshold(uA)    Signal_meaning     Notes
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
                         
                     
//Tabel 2: Input signal to Interlock logic 
//Note: mask bit "1" means valid, i.e. is involved in the logic calculation
//!!! mask bit 0~12 are common for all T1,T2,TNF, and is the same as the Threshold index !!!
//!!! mask bit 13~ 15 are Specific to T1  !!!
// Mask_Index   Signal    Mask_TNF(default) Digi_channel
// 0             U_OK       1             
// 1             D_OK       1             
// 2             L_OK       1
// 3             R_OK       1
// 4             Halo_OK    1 
// 5             Den_OK     1
// 6             Tot_OK     1 
// 7             HV_OK      1
// 8             absLR_OK   1              
// 9             absUD_OK   1                         
// 10            absDT_OK   1                
// 11            SOT_OK     1              
// 12            TMS_OK     1              

// 13             T1VAC_OK   1              0
// 14             T2SUM_OK   1              1  
// 15             TNFSUM_OK  1              2




//Tabel 3: Mapping Backpanel channel to logic channel, using this table when connect physical signal cables.
//backpannel lables:
//Aanalog input: starting from left when facing to the backpanel: ch0, 1,2,to 7
//Relay output: starting from left, top row: ch0,1,2,3, bottom row: ch4,5,6,7
//Digi input: save as above Relay output, top row: ch0,1,2,3, bot row: ch4,5,6,7
//!!! Specific to T1  !!!
//Note: Analog input channel is already matched. The channels not mapped are not in use for T1 logic.
//The following table's 1st colomn is the backpanel channel number.
//It has been already mapped in top module to correct GPIO pins.
//The following mapping were updated after the assembly with
//the metal back panel.
//March 7,2019
//Digi-in PCBch   Signal    
// 0      3   	TNFSUM_OK     
// 1      4   	T2SUM_OK      
// 2      1   	T1VAC_OK      
// 3      2   	T1_SUMMARY, loopback from relay output 0  
// 4      7   	Not defined   
// 5      8   	Not defined   
// 6      5   	Not defined   
// 7      6   	Not defined   

//Realy   PCBch   Signal    
// 0        3     T1_SUMMARY    
// 1        5     HALO_HV_En    
// 2        7     T1_HV_En      
// 3        1     not in use    
// 4        4     T1SUM_SAFETY  
// 5        6     T2SUM_SAFETY  
// 6        8     TNFSUM_SAFETY 
// 7        2     not in use    

//////////////////////////////////////////////////////////////////////////////////
module T1_logic(
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
//parameter  	SF_WIDTH = 32;

//Following added on May 24,2019
//Scale the signal voltage to equal the PIE amplifier gain of T1 protect: 
//based on A-20023 and Mini-PCA gain= 1uA/V
//U,D,L,R = 2.5; Total = 0.5; Halo = 5;
wire signed [ADC_BIT_WIDTH-1:0] U = analog_in[0];
wire signed [ADC_BIT_WIDTH-1:0] D = analog_in[1];
wire signed [ADC_BIT_WIDTH-1:0] L = analog_in[2];
wire signed [ADC_BIT_WIDTH-1:0] R = analog_in[3];
wire signed [ADC_BIT_WIDTH-1:0] Halo = analog_in[4];
wire signed [ADC_BIT_WIDTH-1:0] Den = analog_in[5];
wire signed [ADC_BIT_WIDTH-1:0] Tot = analog_in[6];
wire signed [ADC_BIT_WIDTH-1:0] HV = analog_in[7]; 

wire signed [15:0] SUM_value = (D + U) >>> 1; //0524_2019SL, scaled to be the same unit as Total

wire [ADC_BIT_WIDTH-1:0] Scaled_U = (U <<< 1) + (U >>> 1); //times 2.5
wire [ADC_BIT_WIDTH-1:0] Scaled_D = (D <<< 1) + (D >>> 1);
wire [ADC_BIT_WIDTH-1:0] Scaled_L = (L <<< 1) + (L >>> 1);
wire [ADC_BIT_WIDTH-1:0] Scaled_R = (R <<< 1) + (R >>> 1);

wire [ADC_BIT_WIDTH-1:0] Scaled_Halo = ((Halo <<< 1) + (Halo >>> 1)) <<< 1; //times 5 
wire [ADC_BIT_WIDTH-1:0] Scaled_Den = analog_in[5];
wire [ADC_BIT_WIDTH-1:0] Scaled_Tot = (Tot >>> 1); //times 0.5
wire [ADC_BIT_WIDTH-1:0] Scaled_HV = HV; 


//Assign monitor ananolg signal according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire [ADC_BIT_WIDTH-1:0] U_value = Scaled_U;
wire [ADC_BIT_WIDTH-1:0] D_value = Scaled_D;
wire [ADC_BIT_WIDTH-1:0] L_value = Scaled_L;
wire [ADC_BIT_WIDTH-1:0] R_value = Scaled_R;
wire [ADC_BIT_WIDTH-1:0] Halo_value = Scaled_Halo;
wire [ADC_BIT_WIDTH-1:0] Den_value = Scaled_Den;
wire [ADC_BIT_WIDTH-1:0] Tot_value = Scaled_Tot;
wire [ADC_BIT_WIDTH-1:0] HV_value = Scaled_HV; 

//Assign threshold according to Table 1 above:
//!!! common for all T1,T2,TNF !!!
wire [ADC_BIT_WIDTH-1:0] U_th = thresh[0];
wire [ADC_BIT_WIDTH-1:0] D_th = thresh[1];
wire [ADC_BIT_WIDTH-1:0] L_th = thresh[2];
wire [ADC_BIT_WIDTH-1:0] R_th = thresh[3];
wire [ADC_BIT_WIDTH-1:0] Halo_th = thresh[4];
wire [ADC_BIT_WIDTH-1:0] Den_th = thresh[5];
wire [ADC_BIT_WIDTH-1:0] Tot_th = thresh[6];
wire [ADC_BIT_WIDTH-1:0] HV_th = thresh[7];
wire [ADC_BIT_WIDTH-1:0] LMR_th = thresh[8];
wire [ADC_BIT_WIDTH-1:0] UMD_th = thresh[9];
wire [ADC_BIT_WIDTH-1:0] DMT_th = thresh[10];
wire [ADC_BIT_WIDTH-1:0] SOT_th = thresh[11];
wire [ADC_BIT_WIDTH-1:0] TMS_th = thresh[12];

wire [ADC_BIT_WIDTH-1:0] HV_th_half = {HV_th[15],HV_th[15:1]};
 
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
assign readback[11] = SOT_value;
assign readback[12] = TMS_value;
assign readback[13] = SUM_value;


////////////////////////////////////////////////////////
//Interlock Logic: 
// !!! Specific to T1 !!!

wire [15:0] absLR_value = (L_value > R_value)? L_value-R_value
                  : R_value-L_value;					
wire [15:0] absUD_value = (D_value > U_value)? D_value-U_value
                  : U_value-D_value;
wire [15:0] absDT_value = (Den_value > Tot_value)? Den_value-Tot_value
                  : Tot_value-Den_value; 

//Assign digital input signal according to Table 2 above:
wire T1VAC_OK = digi_in[0];
wire T2SUM_OK = digi_in[1];
wire TNFSUM_OK = digi_in[2];

wire T1SUM_OK = digi_in[3]; //self check purpose, connected to T1SUM_SAFETY Relay[4] at outisde of module

//when optical board lost power, all digi-in becomes "1", 
//thus the ununsed input could be monitored as watch dog signal.
wire WD = (~digi_in[4]) & (~digi_in[5]) & (~digi_in[6]) & (~digi_in[7]);

wire L_OK = L_value[15]? 1'b1 : L_value < L_th;
wire R_OK = R_value[15]? 1'b1 : R_value < R_th;
wire D_OK = D_value[15]? 1'b1 : D_value < D_th;
wire U_OK = U_value[15]? 1'b1 : U_value < U_th;

//wire [15:0] SOT_value_m = ((Tot_value == 0) && (SUM_value == 0))? 16'b0 : Pratio[15:0];
//wire [15:0] SOT_value_m = ((Tot_value[15]) | (SUM_value[15] ))? 16'b0 : Pratio[15:0];

wire SOT_OVL = |Pratio[31:16];
wire unsigned [15:0] SOT_value = SOT_OVL? 16'h7fff : Pratio[15:0];
wire [15:0] TMS_value = Tot_value - SUM_value; 

//Tot_th in T1 is used as the value to enable the SOT trip, 05222019SL;
wire Enable_SOT = Tot_value[15]? 1'b0 : Tot_value > Tot_th;
wire SOT_OK = Enable_SOT? (SOT_value > SOT_th) : 1'b1;
wire HALO_OK = Halo_value[15]? 1'b1 : Halo_value < Halo_th;
 
//wire HV_OK = (HV_value < HV_th) && (HV_value > HV_th_half); //05222019SL: added lower limit
wire HV_OK = (HV_value > HV_th); //08012019SL: only use the lower limit.

wire Umask = ~mask[0];
wire Dmask = ~mask[1];
wire Lmask = ~mask[2];
wire Rmask = ~mask[3];
wire HALOmask = ~mask[4];
wire HVmask = ~mask[7];
wire SOTmask = ~mask[11];
wire TMSmask = ~mask[12];
wire T1VACmask = ~mask[13];
wire T2SUMmask = ~mask[14];
wire TNFSUMmask = ~mask[15];

 
//output relay contacts
wire T1_SUMMARY = WD & (L_OK|Lmask) & (R_OK|Rmask) & (D_OK|Dmask) & (U_OK|Umask) & (SOT_OK|SOTmask) & (HALO_OK|HALOmask) & (HV_OK|HVmask) & (T1VAC_OK|T1VACmask); 
wire HALO_HV_En = T1VAC_OK|T1VACmask;
wire T1_HV_En = T1VAC_OK|T1VACmask;
wire T1SUM_SAFETY = T1SUM_OK;
wire T2SUM_SAFETY = T2SUM_OK|T2SUMmask;
wire TNFSUM_SAFETY = TNFSUM_OK|TNFSUMmask;

wire not_fault = (&relay[2:0]) & (&relay[6:4]); 
assign fault = ~not_fault;


wire [7:0] trip_bit = ~relay;

  
trip_log trip_log_ins(
   .clk(clk),   
	.rst(rst),
	
	.Umask(Umask),
	.Dmask(Dmask),
	.Lmask(Lmask),
	.Rmask(Rmask),
	.HALOmask(HALOmask),
	.HVmask(HVmask),
	.SOTmask(SOTmask),
	.TMSmask(TMSmask),
	.T1VACmask(T1VACmask),
	.T2SUMmask(T2SUMmask),
	.TNFSUMmask(TNFSUMmask),

	.t1_summary(T1_SUMMARY),
	.trip_bit(trip_bit),
	.status(status),
	.fault(fault), 
  
   .last_trip_reg(last_trip_bit)

    );
	 
//----------------------------------------------------------------------

wire [7:0] relay_in;
assign relay_in[0] = T1_SUMMARY; //goes to digi_in[3] for self-checking
assign relay_in[1] = HALO_HV_En;
assign relay_in[2] = T1_HV_En;
assign relay_in[3] = 1'b0; //not in use, set to "0" to save power
assign relay_in[4] = T1SUM_SAFETY;
assign relay_in[5] = T2SUM_SAFETY;
assign relay_in[6] = TNFSUM_SAFETY;
assign relay_in[7] = 1'b0; //not in use, set to "0" to save power
						
assign relay[3] = 0;
assign relay[7] = 0;

assign relay_cnt[3] = 0;
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

//trip 4,5,6
genvar j;
generate 
for (j = 4; j < 7 ; j = j + 1) 
	begin: trip_unit_group2
		trip_unit trip_unit_ins2(
			.clk(clk),   
			.rst(rst),
			.data(relay_in[j]),
			.clear_trip(clear_trip), 
			.state_bits(),	
			.trip_cnt(relay_cnt[j]),
			.relay_reg(relay[j])
    );
		
  	end
endgenerate 
 


//----------------------------------------------------------------------
assign status[0] = WD;  
assign status[1] = L_OK;
assign status[2] = R_OK;  
assign status[3] = D_OK;  
assign status[4] = U_OK;  
assign status[5] = SOT_OK;  
assign status[6] = HALO_OK;  
assign status[7] = HV_OK;  
assign status[8] = T1VAC_OK;  
assign status[9] = T1_SUMMARY; //T1SUM_OK;  
assign status[10] = T2SUM_OK;  
assign status[11] = TNFSUM_OK;  
assign status[16:12] = 5'b00000; //not in use
assign status[17] = relay[0];
assign status[18] = relay[1];
assign status[19] = relay[2];
assign status[20] = 1'b0; //relay[3];
assign status[21] = relay[4];
assign status[22] = relay[5];
assign status[23] = relay[6];
assign status[24] = 1'b0; //relay[7];
assign status[30:25] = 6'b000000; ////not in use
assign status[31] = not_fault;

wire unsigned [15:0] SUM_value_p/*synthesis keep*/;
wire unsigned [15:0] Tot_value_p/*synthesis keep*/;
wire unsigned [15:0] Tot_value_m/*synthesis keep*/;

wire unsigned [31:0] SUM_1000/*synthesis keep*/;
wire unsigned [31:0] Pratio/*synthesis keep*/;

assign SUM_value_p = SUM_value[15]? ~SUM_value : SUM_value;
assign Tot_value_p = Tot_value[15]? ~Tot_value : Tot_value;
assign Tot_value_m = (~(|Tot_value_p))? 1 : Tot_value_p; //prevent divided by 0


lpm_mul	mul_const (
		.dataa(SUM_value_p),
		.datab(16'd1000),
		.result(SUM_1000)
		);	

lpm_div div_const(
	.denom(Tot_value_m),
	.numer(SUM_1000),
	.quotient(Pratio),
	.remain());
	


	
endmodule
