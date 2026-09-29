/*
 * Read conversion results from the slow ADC: AD7417 
 * based on SLADC_read.vi from //UofA/Radon_DAQ project
 * Shengli Liu, Spet.24,2020
 * 
 */
module SLADC
    (
        // Signals to/from AD7417
        output SCL,
        inout SDA,
                                                       

        // Signals to/from system
        input  clk,    // A 50 MHz clock for driving                                                     
        input  rst,    // System Reset
		  
		  output reg [15:0]    DOUT0,       // ADC output 0
		  output reg [15:0]    DOUT1,       // ADC output 1
		  output reg [15:0]    DOUT2,       // ADC output 2
		  output reg [15:0]    DOUT3,       // ADC output 3
        output busy 
    );

  reg read, write, ready;
  assign busy = ~ready;
  
  reg [15:0] FD,GPIFADR;
  reg [7:0] read_address;
 
  AD7417 U_AD7417(
          .IFCLK(clk),
     
          .clk(clk),
          .reset_n(~rst),

          .FD(FD),
          .GPIFADR(GPIFADR),
          .Read_Address(read_address),
          .read(read),
          .write(write),

          .SDA(SDA),
          .SCL(SCL),
          .Temp()        
                     );
							
    parameter   state_idle = 0, 
	             state_cnv = 1,
					 state_wait1 = 2,
					 state_wait2 =3, 
                state_sclk_rise = 4, 
                state_sclk_fall = 5, 
                state_end = 6,
					 state_clr = 7,
					 state_init0 = 8,
					 state_init1 = 9,
					 state_init2 = 10,
					 state_init3 = 11,
					 state_rd0 = 12,
					 state_rd1 = 13,
					 state_rd2 = 14,
					 state_rd3 = 15;
					 

	 
	 reg [4:0] state; /*synthesis keep*/
 

////////////////////////////////////////////////////////////////////////////
always @ (posedge clk) 
begin
	if (rst) 
		begin
			state <= state_idle;
			read <= 0;
			write <= 0;
			ready <= 0;
						
		end
	else 
		case (state)
				state_idle:									
					begin 
						if (start_conv & run)	
						  begin 
						    cnt <= 0;	state <= state_cnv; 
						  end	
						if (start_init)
						  begin 
						    conv <= 1;	 cnt <= 0;	sr <= CONF_BIT; state <= state_init0; 
						  end
						if (start_read) 
						  begin 
						    conv <= 1;	 cnt <= 0;	sr <= READ_BIT; state <= state_rd0; 
						  end  
						else begin conv <= 0; mosi <= 1; sclk <= 0; end  			
					end
///////////////////////////////////////////////////////////////////
				state_cnv:  
				   begin 
					  conv <= 1;					
					  if (cnt >= TCONV) begin cnt <= 0; conv <= 0; state <= state_wait1; end
					  else cnt <= cnt + 1;  	
		         end 
				state_wait1:  state <= state_wait2; 
				state_wait2:  state <= state_sclk_rise; 
				state_sclk_rise:  
					begin          					  
					  sclk <= 1;
					  sr <= {sr[14:0],miso};	
					  state <= state_sclk_fall; 	
		         end
		      state_sclk_fall:  
					begin          					  
					  sclk <= 0; 
					  //sr <= {sr[14:0],miso};	
					  if (cnt >= 15) state <= state_end;
					  else begin cnt <= cnt + 1; state <= state_sclk_rise; end 	
		         end    
				state_end:
					begin  
	              DOUT <= sr;
            	  DRDY <= 1; 
					  cnt <= 0;
					  state <= state_clr;
					end	  
				state_clr:
					begin  
					  if (cnt >= VALID_CYCLE-1) begin  DRDY <= 0; state <= state_idle; end
					  else cnt <= cnt + 1;
					 
					end	     
	////////////////////////////////////////////////////////////////////////////
				state_init0:
					begin          					  
					  conv <= 1;	
					  if (cnt >= CNV_WIDE) begin cnt <= 0; conv <= 0; mosi <= sr[15]; state <= state_init1; end
					  else cnt <= cnt + 1;  	
		         end 
	
				state_init1: 
					begin  
                 				
					  sclk <= 1;
					  sr <= {sr[14:0],1'b0};	
					  state <= state_init2; 	
		         end
		      state_init2:  
					begin          					  
					  sclk <= 0; mosi <= sr[15];
					  if (cnt >= 15) state <= state_init3; 
					  else begin cnt <= cnt + 1; state <= state_init1; end 	
		         end    
				state_init3:  
				   begin init_done <= 1; mosi <= 1; state <= state_idle; end
				
////////////////////////////////////////////////////////				
				state_rd0:
					begin          					  
					  conv <= 1;	
					  if (cnt >= CNV_WIDE) begin cnt <= 0; conv <= 0; mosi <= sr[15]; state <= state_rd1; end
					  else cnt <= cnt + 1;  	
		         end 
	
				state_rd1: 
					begin  
                					
					  sclk <= 1;
					  sr <= {sr[14:0],1'b0};	
					  state <= state_rd2; 	
		         end
		      state_rd2:  
					begin          					  
					  sclk <= 0; mosi <= sr[15]; sr_rd <= {sr_rd[14:0],miso};
					  if (cnt >= 15) state <= state_rd3; 
					  else begin cnt <= cnt + 1; state <= state_rd1; end 	
		         end    
				state_rd3:  
				   begin mosi <= 1; conf_reg <= sr_rd[7:0]; state <= state_idle; end	
					
				default:
				  state <= state_idle;
		
		endcase
		
end //end always

    

endmodule // adc_interface
