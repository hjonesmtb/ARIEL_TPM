`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// Trip_unit:  
// by: Shengli Liu, Diagnostics, TRIUMF
// Histroy: Created on Dec.12,2018
// last modified: 
// 
module trip_unit(
   input clk,   
	input rst,
	input data,
	input clear_trip, //pulse
   output [7:0] state_bits, //for debug
   output reg [7:0] trip_cnt,
   output reg relay_reg

    );
	 
parameter  state_idle = 0; //
parameter  state_wait1 = 1; //
parameter  state_trip = 2; //
parameter  state_clr = 3; //
parameter  state_wait2 = 4; 

reg [3:0] state;
reg [3:0] cnt;

assign state_bits = {4'b0,state};

//reg clear_trip_status;

always @(posedge clk)  
begin
	if (rst )
      begin 	
			state <= state_idle;
			relay_reg <= 0;
			trip_cnt <= 8'b0; 
		end	
	else 
	case (state)
		state_idle:
         begin
			  if (~data) begin cnt <= 0; state <= state_wait1; end
			  else relay_reg <= 1; //normal						
			end
		state_wait1:	
		   begin
				if (data) state <= state_idle;
				else if (&cnt)  state <= state_trip; 
				     else cnt <= cnt + 1; 
		   end
		state_trip: 
			begin
			  relay_reg <= 0;  //tripped 
			  trip_cnt <=  trip_cnt + 1'b1;	
			  //clear_trip_status <= clear_trip;
			  state <= state_clr;
			end
			
		state_clr: if (clear_trip) 
		               begin cnt <= 0; state <= state_wait2; end
		state_wait2:	
		   begin
				if (~data) state <= state_clr;
				else if (&cnt)  state <= state_idle; 
				     else cnt <= cnt + 1; 
		   end
		
			
		default: state <= state_idle;
		
	endcase
		
end //always

endmodule