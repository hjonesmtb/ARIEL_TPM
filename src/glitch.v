`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 
// clitch:  remove the glitchs on the digital input lines
// clitch could occur on the digital input which is 100 ns wide negtive pulse "0" when 
// the realy actions. I have not seen "1" glitchs. 
// by: Shengli Liu, Diagnostics, TRIUMF
// last modified: May 30,2019 
// 
module glitch(
   input clk,  //50 Mhz clk 
	input in,
	output reg out

    );
	 

parameter  state_idle = 0; //
parameter  state_trip = 1; //

parameter MAX_CNT = 10;

reg [2:0] cnt;

always @(posedge clk)
begin
	if (~in) 
		begin 
		   if (&cnt) out <= 1'b0;
			else cnt <= cnt +1; 
	   end
	else begin cnt <= 0; out <= 1'b1; end
	
end //always

endmodule