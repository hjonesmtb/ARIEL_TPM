
module sr(
	input clk,
	input clear_trip,
	input tripped,
	output reg tripped_reg
);


	reg clear_trip_resyn = 0;

	always@(posedge clk) begin // for synchronous reset
		clear_trip_resyn <= clear_trip;
		case({tripped,clear_trip_resyn})
		  2'b00: tripped_reg <= tripped_reg; // No change
		  2'b01: tripped_reg <= 1'b0; // reset
		  2'b10: tripped_reg <= 1'b1; // set
		  2'b11: tripped_reg <= 1'b1; // Invalid inputs
		endcase
	end


endmodule
