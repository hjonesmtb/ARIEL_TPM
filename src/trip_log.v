`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: for T1 target protect so far 
// Trip_log: 
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: 
// 
module trip_log(
   input clk,   
	input rst,
	
	input Umask,
	input Dmask,
	input Lmask,
	input Rmask,
	input HALOmask,
	input HVmask,
	input SOTmask,
	input TMSmask,
	input T1VACmask,
	input T2SUMmask,
	input TNFSUMmask,
	
	input t1_summary,
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
					  
			  last_trip_reg[0] = trip_bit[0]; //realy[0]
			  last_trip_reg[1] = trip_bit[1] & ~T1VACmask; //relay[1]
			  last_trip_reg[2] = trip_bit[2] & ~T1VACmask; //realy[2]
			  last_trip_reg[3] = 1'b0;
			  last_trip_reg[4] = 1'b0;       //note: trip[4] is the loopback of trip[0]
			  last_trip_reg[5] = trip_bit[5] & ~T2SUMmask;  //relay[5]
			  last_trip_reg[6] = trip_bit[6] & ~TNFSUMmask; //relay[6]
			  last_trip_reg[7] = 1'b0;
			  last_trip_reg[15:8] = 8'b0;
			  
			  if (~t1_summary) 
			     begin 	
						last_trip_reg[16] = ~status[0]; //status[0]
						last_trip_reg[17] = ~status[1] & ~Lmask;//status[1]
						last_trip_reg[18] = ~status[2] & ~Rmask;//status[2]
						last_trip_reg[19] = ~status[3] & ~Dmask;//status[3]
						last_trip_reg[20] = ~status[4] & ~Umask;//status[4]
						last_trip_reg[21] = ~status[5] & ~SOTmask;//status[5]
						last_trip_reg[22] = ~status[6] & ~HALOmask;//status[6]
						last_trip_reg[23] = ~status[7] & ~HVmask;//status[7]
						last_trip_reg[24] = ~status[8] & ~T1VACmask;//status[8]
						last_trip_reg[25] = ~status[9] & 1'b0; //status[9]
						last_trip_reg[26] = ~status[10] & ~T2SUMmask;//status[10]
						last_trip_reg[27] = ~status[11] & ~TNFSUMmask;//status[11]
						last_trip_reg[31:28] = 4'b0;				
				  end //if		
			  state <= state_wait;
			end
      state_wait: if (~fault) state <= state_idle;
		
		default: state <= state_idle;
		
	endcase
		
end //always

endmodule


