// AD7417: to access 3 AD7417 chips on the board
//
// S.L. January 22, 2009

//only support:
//write 1 byte to AD7417 register;
//write 1 byte to AD7417 pointer register;
//read 2 bytes from AD7417 register;

//total 10 addresses used in this module:
//          8 to 13 W - write to AD7417 register, 
//          14 W - write to AD7417 pointer register
//          15 R - 16 bit status reg for Slow_ADC module
//               - 16'h0001 data reg valid,
//                 indicates that the previous read command is finished
//               - 16'h0002 busy
//               - 16'h0004 error
//          16 R = 16 bit data reg for Slow_ADC module
//          17 W - read command for AD7417, FD contains AD7417 pointer address
//          18 W - AD7417 address

//To read a register in the AD7417, take the register address from the data 
//sheet and write it to addr 14, then write it to register 17 in the FPGA.  Monitor 
//the status register at address 15 until the least significant bit goes high to 
//indicate that the FPGA has finished reading the AD7417 register.  
//Then read the value from the data register at address 16.

//To write to a register in the AD7417, write to addresses 8 to 13.  
//These address are the register address from the data sheet + 8.  To 
//write to the pointer register in the AD7417, write to address 14.

`timescale 1 ns / 1 ps

module AD7417(
          IFCLK,
          clk,   
          reset_n,
          
          FD,
          GPIFADR,
          Read_Address,
          read,
          write,

          SDA,
          SCL, 
          Temp         
                     );

   parameter USB_WORD_SIZE = 16;
   parameter ID_WORD_SIZE = 3;
   parameter USB_ADDR_SIZE = 5;

   parameter register_base_addr = 8;
   parameter pointer_addr = 14;
   parameter status_addr = 15;
   parameter data_addr = 16;
   parameter command_addr = 17;
   parameter device_addr = 18;


   input IFCLK;
   input clk;
   input reset_n;               

   inout [USB_WORD_SIZE-1:0] FD;
   input [USB_ADDR_SIZE-1 :0] GPIFADR;
   input [7:0] Read_Address;
   input read, write;

   output SCL;
   inout SDA;
   output [7:0] Temp;
   
   
   reg  [2:0] i2c_addr;
   reg  [7:0] in_data;
   wire [7:0] out_data;  
   reg        i2c_cs;
   reg        i2c_rd;
   reg        i2c_wr;


i2c_master i2c_master_inst(
   .addr(i2c_addr), 
   .in_data(in_data), 
   .out_data(out_data), 
   .sda(SDA), 
   .scl(SCL), 
   .cs(i2c_cs), 
   .rd(i2c_rd), 
   .wr(i2c_wr), 
   .clk(IFCLK));

      

   reg [15:0] data;
   reg [15:0] status;
   reg [7:0] addr;

   reg [1:0] bytes;
   reg [7:0] pointer;
   reg [6:0] AD7417_ADDR;
   reg [15:0] buffer;
   
   parameter temperature_value = 0;
   parameter config_register = 1;
   parameter thyst_register = 2;
   parameter toti_register = 3;
   parameter adc_value = 4;
   parameter config2_register = 5;
   parameter pointer_register = 6;
   
   parameter state_idle =        0,
            state_read_start1 =  2,
            state_read_start2 =  3,
            state_read_query0 =  4,
             state_read_addr1 =  5,
            state_read_addr2 =   6,
            state_read_query1 =  7,

            state_read_data1 =   8,
            state_read_data2 =   9,
            state_read_query2 =  10,
            
            state_read_buffer1 = 11,
            state_read_buffer2 = 12,
            
            state_read_data3 =   13,
            state_read_data4 =   14,
             
            state_read_query3 =  15,
            
            state_read_buffer3 = 16,
            state_read_buffer4 = 17,
                        
            state_write_start1 = 18,
            state_write_start2 = 19,
            state_write_query0 = 20,
            
            state_write_addr1 =  21,
            state_write_addr2 =  22,
            state_write_query1 = 23,

            state_write_pointer1 = 24,
            state_write_pointer2 = 25,
            state_write_query2 =   26,
            
            state_write_data1 =   27,
            state_write_data2 =   28,
            state_write_query3 =  29,
                      
            state_stop1 =         30,
            state_stop2 =         31,
            state_stop_query =    32;   
            
   reg [5:0] state;
   reg [5:0] next_state;
   reg clear_next_state;
   
   assign Temp = {3'b0,state};
    
   reg Drive_Status, Drive_Data;
   assign FD = Drive_Status? status
            : Drive_Data? data
            : 16'bz
            ;

   parameter state2_idle = 2'd0,
            state2_read_data_reg = 2'd1;
   
   reg [1:0] state2;
   
   always @( posedge IFCLK or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
          AD7417_ADDR = 7'b0101000;
          Drive_Status <=0;
          Drive_Data <= 0;
          next_state <= state_idle;
          state2 <= state2_idle;
       end
       else
       begin
           case( state2 )
               state2_idle:
                  begin
                     if( clear_next_state )
                     begin
                         next_state <= state_idle;
                     end
                     if( read  && (Read_Address == status_addr))  // status reg for this FPGA module
                     begin
                        Drive_Status <= 1;
                        state2 <= state2_read_data_reg;
                     end
                     if( read  && (Read_Address == data_addr))   // data reg for this FPGA module
                     begin
                        Drive_Data <= 1;
                        state2 <= state2_read_data_reg;
                     end
                     if( write && (GPIFADR == device_addr) )
                     begin
                         AD7417_ADDR = {4'b0101,FD[2:0]};
                     end
                     if( write && (GPIFADR == command_addr) )  // trigger read from SADC
                     begin
                        pointer <= FD[7:0];
                        addr <= {AD7417_ADDR,1'b1};
                        case( FD[7:0] )
                           temperature_value:
                              bytes <= 2;
                           config_register:
                              bytes <= 1;
                           thyst_register:
                              bytes <= 2;
                           toti_register:
                              bytes <= 2;
                           adc_value:
                              bytes <= 2;
                           config2_register:
                              bytes <= 1;
                           default:
                              bytes <= 1;
                        endcase
                        next_state <= state_read_start1;
                     end
                     if( write  && (GPIFADR[4:3] == 2'b01) )   // write to SADC registers
                     begin
                        pointer <= {5'b0,GPIFADR[2:0]};
                        buffer <= FD;
                        addr <= {AD7417_ADDR,1'b0};
                        case( GPIFADR[2:0] )
                           temperature_value:
                              bytes <= 2;
                           config_register:
                              bytes <= 1;
                           thyst_register:
                              bytes <= 2;
                           toti_register:
                              bytes <= 2;
                           adc_value:
                              bytes <= 2;
                           config2_register:
                              bytes <= 1;
                           pointer_register:
                              begin
                                bytes <= 0;
                                pointer <= {5'b0,FD[2:0]};
                              end
                           default:
                              bytes <= 1;
                        endcase
                        next_state <= state_write_start1;
                     end
                  end
                  state2_read_data_reg:
                  begin
                     if( !read )
                     begin
                        Drive_Data <= 0;
                        Drive_Status <= 0;
                        state2 <= state2_idle;
                     end
                  end
                  default:
                  begin
                      state2 <= state2_idle;
                  end
            endcase
      end
   end
   
   ////////////////////////////////////////////////////////////////////////
       
   always @( posedge IFCLK or negedge reset_n )
   begin
       if( reset_n == 0 )
       begin
           i2c_addr <= 0;
           in_data <= 0;
           i2c_cs <= 0;
           i2c_rd <= 0;
           i2c_wr <= 0;
           
           data <= 0;
           status <= 0;
           clear_next_state <= 0;
           state <= state_idle;
       end
       else
          case( state )
              state_idle:
              begin
                  i2c_addr <= 0; in_data <= 0; i2c_cs <= 0; i2c_wr <= 0; i2c_rd <= 0;
                  status <= status & 16'hFFFD;   // clear busy
                  if( next_state != state_idle )
                    begin
                      state <= next_state;
                      clear_next_state <= 1;
                    end
              end
              
              state_read_start1:
                begin
                 
                 status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 
                 i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;
                 
                 state <= state_read_start2;
                end
              
              state_read_start2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_read_query0;
                end
              
              state_read_query0:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_read_addr1;
                     end
                end
                          
              state_read_addr1:
                begin
                  i2c_addr <= 3; in_data <= addr; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_read_addr2;
                end
                
              state_read_addr2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_read_query1;
                end    
                          
              state_read_query1:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_read_data1;
                     end
                end
             
             state_read_data1:
                begin
                  i2c_addr <= 2; in_data <= 1; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_read_data2;
                end
              
              state_read_data2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_read_query2;
                end  
              
              state_read_query2:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_read_buffer1;
                     end
                end   
                
               state_read_buffer1:
                 begin
                  i2c_addr <= 3; i2c_cs <= 1; i2c_rd <= 1;
                  state <= state_read_buffer2;
                 end    
             
              state_read_buffer2:
                 begin
                  data[15:8] <= out_data;
                  i2c_cs <= 0; i2c_rd <= 0;
                  state <= state_read_data3;
                 end  
                 
              state_read_data3:
                begin
                  i2c_addr <= 2; in_data <= 0; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_read_data4;
                end
              
              state_read_data4:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_read_query3;
                end  
              
              state_read_query3:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_read_buffer3;
                     end
                end   
              
              state_read_buffer3:
                 begin
                  i2c_addr <= 3; i2c_cs <= 1; i2c_rd <= 1;
                  state <= state_read_buffer4;
                 end    
             
              state_read_buffer4:
                 begin
                  data[7:0] <= out_data;
                  i2c_cs <= 0; i2c_rd <= 0;
                  status <= status | 16'h0001;   // set data valid flag
                 
                  state <= state_stop1;
                 end    
              
     
              /////////////////////////////////////////////////////////////////
                     
              
              state_write_start1:
                begin
                  
                  status <= (status | 16'h0002) & 16'hFFFA;  // set busy, clear data valid & error
                 
                  i2c_addr <= 0; i2c_cs <= 1; i2c_wr <= 1;
                 
                  state <= state_write_start2;
                end
                
              state_write_start2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_write_query0;
                end
                
              state_write_query0:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_write_addr1;
                     end
                end
                
              state_write_addr1:
                begin
                  i2c_addr <= 3; in_data <= addr; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_write_addr2;
                end
                
              state_write_addr2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_write_query1;
                end    
                          
              state_write_query1:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_write_pointer1;
                     end
                end
                
              state_write_pointer1:
                begin
                  i2c_addr <= 3; in_data <= pointer; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_write_pointer2;
                end
                
              state_write_pointer2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_write_query2;
                end   
                
              state_write_query2:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       if (bytes == 0)
                          state <= state_stop1;
                       else state <= state_write_data1;
                     end
                end   
             
              state_write_data1:
                begin
                  i2c_addr <= 3; in_data <= buffer[7:0]; i2c_cs <= 1; i2c_wr <= 1;
                  state <= state_write_data2;
                end
              
              state_write_data2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_write_query3;
                end  
              
              state_write_query3:
                begin
                  i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_stop1;
                     end
                end   
                
              state_stop1:
                begin
                 i2c_addr <= 1; i2c_cs <= 1; i2c_wr <= 1;
                 state <=  state_stop2;
                 clear_next_state <= 0;
                end
                
              state_stop2:
                begin
                  i2c_cs <= 0; i2c_wr <= 0;
                  state <= state_stop_query;
                end
                
              state_stop_query:
                begin
                 i2c_addr <= 4; i2c_cs <= 1; i2c_rd <= 1;
                  if (out_data[0] == 0)
                     begin 
                       i2c_cs <= 0; i2c_rd <= 0;
                       state <= state_idle;
                     end
                end
                
              default:
                begin
                  state <= state_idle;
                end
                
          endcase
   end
 

endmodule