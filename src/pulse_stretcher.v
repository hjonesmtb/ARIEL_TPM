module pulse_stretcher #(
    parameter STRETCH_LEN = 9
)(
    input wire clk,
    input wire pulse_in,    // input pulse (1 clock wide)
    output reg pulse_out=0    // output pulse (8 clocks wide)
);

    reg [7:0] counter=0;
    reg active=0;

    always @(posedge clk) begin
		if (pulse_in && !active) begin
			// Start stretching
			counter   <= 0;
			pulse_out <= 1;
			active    <= 1;
		end else if (active) begin
			 if (counter == STRETCH_LEN - 1) begin
				  pulse_out <= 0;
				  active    <= 0;
			 end else begin
				  counter <= counter + 1;
                end
         end
        
    end

endmodule
