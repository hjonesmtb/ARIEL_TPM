`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: for T2 target protect 
// Trip_log_tnf.v
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: Nov.25,2019: modified trip_log.v to be for T2 protect logic
// 

module trip_log_T2(
   input clk,   
	input rst,
	
	input Umask,
	input Dmask,
	input Lmask,
	input Rmask,
	input HALOmask,
	input HVmask,
	input TMSmask,
	input VACmask,

	input T2_SUMMARY,
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
			  last_trip_reg[1] = ~status[1] & ~Lmask;//status[1]
			  last_trip_reg[2] = ~status[2] & ~Rmask;//status[2]
			  last_trip_reg[3] = ~status[3] & ~Dmask;//status[3]
			  last_trip_reg[4] = ~status[4] & ~Umask;//status[4]
			  last_trip_reg[5] = ~status[5] & ~TMSmask;//status[5]
			  last_trip_reg[6] = ~status[6] & ~HALOmask;//status[6]
			  last_trip_reg[7] = ~status[7] & ~HVmask;//status[7]
			  last_trip_reg[8] = ~status[8] & ~VACmask;//status[8]
			  
			  last_trip_reg[16:9] = 8'b0; 
			  
			  last_trip_reg[17] = trip_bit[0]; //realy[0], T2_Summary
			  last_trip_reg[18] = trip_bit[1] & ~VACmask; //relay[1], Prot_HV_enable
			  last_trip_reg[19] = trip_bit[2] & ~VACmask; //realy[2], Sem_Hv_enable
			  			  
			  last_trip_reg[31:20] = 11'b0;				
					
			  state <= state_wait;
			end
      state_wait: if (~fault) state <= state_idle;
		
		default: state <= state_idle;
		
	endcase
		
end //always

endmodule

