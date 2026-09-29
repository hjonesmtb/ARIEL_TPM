`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: for TNF target protect 
// Trip_log_tnf.v
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: Nov.14,2019: modified trip_log.v to be for TNF protect logic
// 

module trip_log_TNF(
   input clk,   
	input rst,
	
	input absLR_mask,
	input absDU_mask,
	input absDT_mask,
	input Halo_mask,
	input T30uA_mask,
	input T80uA_mask,
	input HV_mask,
	input Prof_mask,
	input Prot_mask,
	input TRIMAC_mask,
	input VAC_mask,

	input TNF_SUMMARY,
	input [7:0] trip_bit,
	input [31:0] status,
	input fault, 
  
   output reg [31:0] last_trip_reg

    );
	 
parameter  state_idle = 0; //
parameter  state_trip = 1; //
parameter  state_wait = 2; //

reg [2:0] state;

assign state_bits = {4'b0,state};

reg clear_trip_status;

always @(posedge clk)  
begin
	if (rst )
      begin 	
			state <= state_idle;
			last_trip_reg <= 0;
		end	
	else 
	case (state)
		state_idle: if (fault) state <= state_trip; 				
		state_trip: 
			begin
			  last_trip_reg[0] = ~status[0]; //status[0], Watchdog
			  last_trip_reg[1] = ~status[1] & ~absLR_mask;//status[1]
			  last_trip_reg[2] = ~status[2] & ~absDU_mask;//status[2]
			  last_trip_reg[3] = ~status[3] & ~absDT_mask;//status[3]
			  last_trip_reg[4] = ~status[4] & ~Halo_mask;//status[4]
			  last_trip_reg[5] = ~status[5] & ~T30uA_mask;//status[5]
			  last_trip_reg[6] = ~status[6] & ~T80uA_mask;//status[6]
			  last_trip_reg[7] = ~status[7] & ~HV_mask;//status[7]
			  last_trip_reg[8] = ~status[8] & ~Prof_mask;//status[8]
			  last_trip_reg[9] = ~status[9] & ~Prot_mask; //status[9]
			  last_trip_reg[10] = ~status[10] & ~TRIMAC_mask;//status[10]
			  last_trip_reg[11] = ~status[11] & ~VAC_mask;//status[11]
			  
			  last_trip_reg[16:12] = 5'b0; 
			  
			  last_trip_reg[17] = trip_bit[0]; //realy[0], TNF_Summary
			  last_trip_reg[18] = trip_bit[1] & ~Prof_mask; //relay[1], Prof_HV_enable
			  last_trip_reg[19] = trip_bit[2] & ~VAC_mask; //realy[2], Prot_Hv_enable
			  last_trip_reg[20] = trip_bit[3] & ~absDT_mask; //realy[3], DT_en
			  
			  last_trip_reg[31:21] = 11'b0;				
					
			  state <= state_wait;
			end
      state_wait: if (~fault) state <= state_idle;
		
		default: state <= state_idle;
		
	endcase
		
end //always

endmodule

