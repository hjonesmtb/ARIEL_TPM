/*
 * Top Level system description for AETE Fast Target Protect module.
 * This project was based upon BL1A Target Protect Module.
 * Holden Jones
 * June 2025
 */

//----------------------------------
// notes: June 2026 - Added CIC decimation inside calc_current to filter noise. Ch_I_value is now at 1126 Hz.
// 
//-----------------------------
module DE10_NANO_SoC_GHRD(

    //////////// CLOCK //////////
    input               FPGA_CLK1_50,
    input               FPGA_CLK2_50,
    input               FPGA_CLK3_50,

    //////////// HDMI //////////
    inout               HDMI_I2C_SCL,
    inout               HDMI_I2C_SDA,
    inout               HDMI_I2S,
    inout               HDMI_LRCLK,
    inout               HDMI_MCLK,
    inout               HDMI_SCLK,
    output              HDMI_TX_CLK,
    output   [23: 0]    HDMI_TX_D,
    output              HDMI_TX_DE,
    output              HDMI_TX_HS,
    input               HDMI_TX_INT,
    output              HDMI_TX_VS,

    //////////// HPS //////////
    inout               HPS_CONV_USB_N,
    output   [14: 0]    HPS_DDR3_ADDR,
    output   [ 2: 0]    HPS_DDR3_BA,
    output              HPS_DDR3_CAS_N,
    output              HPS_DDR3_CK_N,
    output              HPS_DDR3_CK_P,
    output              HPS_DDR3_CKE,
    output              HPS_DDR3_CS_N,
    output   [ 3: 0]    HPS_DDR3_DM,
    inout    [31: 0]    HPS_DDR3_DQ,
    inout    [ 3: 0]    HPS_DDR3_DQS_N,
    inout    [ 3: 0]    HPS_DDR3_DQS_P,
    output              HPS_DDR3_ODT,
    output              HPS_DDR3_RAS_N,
    output              HPS_DDR3_RESET_N,
    input               HPS_DDR3_RZQ,
    output              HPS_DDR3_WE_N,
    output              HPS_ENET_GTX_CLK,
    inout               HPS_ENET_INT_N,
    output              HPS_ENET_MDC,
    inout               HPS_ENET_MDIO,
    input               HPS_ENET_RX_CLK,
    input    [ 3: 0]    HPS_ENET_RX_DATA,
    input               HPS_ENET_RX_DV,
    output   [ 3: 0]    HPS_ENET_TX_DATA,
    output              HPS_ENET_TX_EN,
    inout               HPS_GSENSOR_INT,
    inout               HPS_I2C0_SCLK,
    inout               HPS_I2C0_SDAT,
    inout               HPS_I2C1_SCLK,
    inout               HPS_I2C1_SDAT,
    inout               HPS_KEY,
    inout               HPS_LED,
    inout               HPS_LTC_GPIO,
    output              HPS_SD_CLK,
    inout               HPS_SD_CMD,
    inout    [ 3: 0]    HPS_SD_DATA,
    output              HPS_SPIM_CLK,
    input               HPS_SPIM_MISO,
    output              HPS_SPIM_MOSI,
    inout               HPS_SPIM_SS,
    input               HPS_UART_RX,
    output              HPS_UART_TX,
    input               HPS_USB_CLKOUT,
    inout    [ 7: 0]    HPS_USB_DATA,
    input               HPS_USB_DIR,
    input               HPS_USB_NXT,
    output              HPS_USB_STP,

	 //////////// GPIO //////////
	 output GPIO_1_35, //pca_gain1
	 output GPIO_1_34, //pca_gain0
	 
	 output GPIO_1_20,  //SqureWave for self testing
	 output GPIO_1_24,  //Test_on
	
	 input  GPIO_1_0,  //HPS_Cold_Reset 
	 output GPIO_1_3,  //LED_COMM
	 output GPIO_1_5,  //LED_FPGA
	 output GPIO_1_2,  //LED_Fault
	 output GPIO_1_32,  //TRIP output
		 
	 //i2c eeprom
	 output GPIO_1_6, //SCL
	 inout  GPIO_1_8, //SDA
	
 
	//Digital Input from P2 connector of MotherBoard
    input  GPIO_1_10, //Test 0 = Digital In 0
	 input  GPIO_1_11, //Test 1 = Digital In 1
	 input  GPIO_1_12, //Test 2 = Digital In 2
	 input  GPIO_1_13, //Test 3 = Digital In 3
	 input  GPIO_1_14, //Test 4 = Digital In 4
	 input  GPIO_1_15, //Test 5 = Digital In 5
	 
	 output GPIO_1_17, //Test 6 = OP_TX
	 input  GPIO_1_18, //Test 7 = OP_RC
 	 
	 //inout  GPIO_1_18, //Test 8 = DHT11 Sig
	 

   
	//Ch1--Ch1 of PCB Analog Input channel
	input  GPIO_0_4,  //SDO
	output GPIO_0_3, //SCLK
   output GPIO_0_5,  //CONV
	
	//Ch2--Ch2 of PCB Analog Input channel
	input  GPIO_0_8,  //SDO
	output GPIO_0_7, //SCLK
   output GPIO_0_9,  //CONV

	//Ch3--Ch3 of PCB Analog Input channel
	input  GPIO_0_12,  //SDO
	output GPIO_0_11, //SCLK
   output GPIO_0_13,  //CONV

	//Ch4--Ch4 of PCB Analog Input channel
	input  GPIO_0_16,  //SDO
	output GPIO_0_15, //SCLK
   output GPIO_0_17,  //CONV

	//Ch5--Ch5 of PCB Analog Input channel
	input  GPIO_0_20,  //SDO
	output GPIO_0_19, //SCLK
   output GPIO_0_21,  //CONV

	//Ch6--Ch6 of PCB Analog Input channel
	input  GPIO_0_26,  //SDO
	output GPIO_0_25, //SCLK
   output GPIO_0_27,  //CONV

	//Ch7--Ch7 of PCB Analog Input channel
	input  GPIO_0_30,  //SDO
	output GPIO_0_29, //SCLK
   output GPIO_0_31,  //CONV

	//Ch8--Ch8 of PCB Analog Input channel
	input  GPIO_0_34,  //SDO
	output GPIO_0_33, //SCLK
   output GPIO_0_35,  //CONV
	
		 
    //////////// KEY //////////
    input    [ 1: 0]    KEY,

    //////////// LED //////////
    output   [ 7: 0]    LED,

    //////////// SW //////////
    input    [ 3: 0]    SW
);

//parameter FPGA_VERSION_NO = 32'd0020200908; //nn_yyyy_mm_dd: AETE nn=00;
parameter FPGA_VERSION_NO = 32'd20261029; // d20260721
parameter IS_AETE = 0; // select between AETE (1) and APTW (0)

`include "src/param.v"

`define 	PCA_GAIN_BIT_L8 configuration[0]
`define 	PCA_GAIN_BIT_H8 configuration[1]

`define 	CON_REG_L8 configuration[2]
`define 	CON_REG_H8 configuration[3]

`define 	MASK_REG_L8 configuration[4]
`define 	MASK_REG_H8 configuration[5]

`define 	TRIP_TH0  {configuration[11],configuration[10]}
`define 	TRIP_TH1  {configuration[13],configuration[12]}
`define 	TRIP_TH2  {configuration[15],configuration[14]}
`define 	TRIP_TH3  {configuration[17],configuration[16]}
`define 	TRIP_TH4  {configuration[19],configuration[18]}
`define 	TRIP_TH5  {configuration[21],configuration[20]}
`define 	TRIP_TH6  {configuration[23],configuration[22]}
`define 	TRIP_TH7  {configuration[25],configuration[24]}

`define 	TRIP_TH8  {configuration[27],configuration[26]}
`define 	TRIP_TH9  {configuration[29],configuration[28]}
`define 	TRIP_TH10  {configuration[31],configuration[30]}
`define 	TRIP_TH11  {configuration[33],configuration[32]}
`define 	TRIP_TH12  {configuration[35],configuration[34]}
`define 	TRIP_TH13  {configuration[37],configuration[36]}
`define 	TRIP_TH14  {configuration[39],configuration[38]}
`define 	TRIP_TH15  {configuration[41],configuration[40]}

//`define 	AVG_SHIFT  {configuration[27],configuration[26]}

wire signed [ADC_DATA_WIDTH-1:0] trip_thresh[15:0];
 
genvar i;
generate 
for (i = 0; i < 31 ; i = i + 2) 
	begin: thresh_assignment
		assign trip_thresh[i>>1] = {configuration[i+11],configuration[i+10]};
  	end
endgenerate 
										
//=======================================================
//  REG/WIRE declarations
//=======================================================
wire hps_fpga_reset_n;
wire     [1: 0]     fpga_debounced_buttons;
wire     [6: 0]     fpga_led_internal;
wire     [2: 0]     hps_reset_req;
wire                hps_cold_reset;
wire                hps_warm_reset;
wire                hps_debug_reset;
wire     [27: 0]    stm_hw_events;
wire                fpga_clk_50;

// connection of internal logics

assign LED[7: 1] = fpga_led_internal;
assign fpga_clk_50 = FPGA_CLK1_50;
assign stm_hw_events = {{15{1'b0}}, SW, fpga_led_internal, fpga_debounced_buttons};

/************************************************************************/
/************************* Target Protect Logic *************************/
/************************************************************************/

//`define T1_TARGET 1
`define AETE 1

wire self_chk, test_pulse;

//ADC interface

wire [7:0] ADC_MISO;
wire [7:0] ADC_CONV;
wire [7:0] ADC_SCLK;

wire [7:0] d_in,digi_in; //logic signal input 6 channel. GPIO_1_10 - GPIO_1_15

//I2C signal for eeprom for configuration data
wire eeprom_scl,eeprom_sda;

wire [1:0] pca_gain; //All 8 channel PCA have the same gain. 

wire Cold_Reset_Req, LED_COMM, LED_FPGA, LED_Fault;
assign LED_Fault = interlock_status[0]; // tripped

//assign LED_CNF_DONE = Cold_Reset_Req; //I don't know how to use this LED so far.

// GPIO pin mapping :
  
	assign GPIO_1_20 = test_pulse;  //test pulse: squre wave
	assign GPIO_1_24 = self_chk; //Turn-onlog Switch for Sigma-Delta signal
	
	assign Cold_Reset_Req = ~GPIO_1_0;  //HPS_Cold_Reset 
	assign GPIO_1_3 = LED_COMM;  //LED_COMM, indicating communication activity, not implemented yet.
	assign GPIO_1_5 = LED_FPGA;  //LED_FPGA
	assign GPIO_1_2 = LED_Fault;  //LED_Fault
	assign GPIO_1_32 = LED_Fault; // TRIP output
	
	assign d_in[5] = ~GPIO_1_10; //digital input 6
	assign d_in[4] = ~GPIO_1_11; 
	assign d_in[3] = ~GPIO_1_12; 
	assign d_in[2] = ~GPIO_1_13; 
	assign d_in[1] = ~GPIO_1_14; 
	assign d_in[0] = ~GPIO_1_15; //digital input 1
	
	wire  OPT_out; //fiber optical signal output (TX)
	assign GPIO_1_17 = OPT_out;
	wire  OPT_in  = GPIO_1_18; //fiber optical signal input (RX)
	
//GPIO_1_18 assigned in module instance directly
//GPIO_1_6,8 assigned in module instance directly
 
   assign {GPIO_1_35,GPIO_1_34} = pca_gain;
	
	assign ADC_MISO[0]  =  GPIO_0_4; //Ch0--Ch1 of PCB channel
	assign GPIO_0_3 = ADC_SCLK[0];
	assign GPIO_0_5 = ADC_CONV[0];
	
	assign ADC_MISO[1]  =  GPIO_0_8; //Ch1--Ch2 of PCB channel
	assign GPIO_0_7 = ADC_SCLK[1];
	assign GPIO_0_9 = ADC_CONV[1];
	
	assign ADC_MISO[2]  =  GPIO_0_12; //Ch2--Ch3 of PCB channel
	assign GPIO_0_11 = ADC_SCLK[2];
	assign GPIO_0_13 = ADC_CONV[2];
	
	assign ADC_MISO[3]  =  GPIO_0_16;//Ch3--Ch4 of PCB channel
	assign GPIO_0_15 = ADC_SCLK[3];
	assign GPIO_0_17 = ADC_CONV[3];
	
	assign ADC_MISO[4]  =  GPIO_0_20;//Ch4--Ch5 of PCB channel
	assign GPIO_0_19 = ADC_SCLK[4];
	assign GPIO_0_21 = ADC_CONV[4];
	
	assign ADC_MISO[5]  =  GPIO_0_26;//Ch5--Ch6 of PCB channel
	assign GPIO_0_25 = ADC_SCLK[5];
	assign GPIO_0_27 = ADC_CONV[5];
	
	assign ADC_MISO[6]  =  GPIO_0_30;//Ch6--Ch7 of PCB channel
	assign GPIO_0_29 = ADC_SCLK[6];
	assign GPIO_0_31 = ADC_CONV[6];
	
	assign ADC_MISO[7]  =  GPIO_0_34;//Ch7--Ch8 of PCB channel
	assign GPIO_0_33 = ADC_SCLK[7];
	assign GPIO_0_35 = ADC_CONV[7];
	
// clock generation
wire SYS_CLK;
wire SYS_RST;
wire pll_locked; //this signal could be used to initialize ADC?

wire SCLK,CLK140M;
assign SYS_RST = ~hps_fpga_reset_n;


clk140_pll clk_pll_inst0 
	(
		.refclk(FPGA_CLK1_50),
		.rst(SYS_RST),
		.outclk_0(SYS_CLK), // 50 MHz system clock
		.outclk_1(CLK140M),  // 140 MHz ADC driving clock
		.outclk_2(SCLK), //35 Mhz clock
		.locked(pll_locked)  //locked output
	);


///////////////////////////////////////////////
//Clean glitches on digital inputs
//Glitches may occur when relay actions

genvar j;
generate 
for (j = 0; j < 6 ; j = j + 1) 
	begin: digi_clean
		glitch glitch_ins(
			.clk(SYS_CLK),   
			.in(d_in[j]),
			.out(digi_in[j])
    );
		
  	end
endgenerate 

///
//read slow ADC
//January 15,2021: 
//need to add files SLADC.v to project, it's not complete and not pass compile, so temperly removed from project
//for testing the optical board input function. 
/*
 SLADC SLADC_inst(
 
 
 )
*/

//////////////////////////////////////////////////////////////////////	
wire signed [ADC_DATA_WIDTH-1:0] ADC_INTERFACE_DOUT [7:0];
reg signed [ADC_DATA_WIDTH-1:0] Ch_ADC_Reg[7:0]; // added sign - HJ
wire  ADC_data_valid;	

AD4001 adc_interface_0
	(  .run(1'b1),
		.miso(ADC_MISO[0]),
		//.mosi(),
		.sclk(ADC_SCLK[0]),
		.ss(ADC_CONV[0]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[0]), //syn to SCLK
		.DRDY(ADC_data_valid) //  one SCLK period
	);

AD4001 adc_interface_1
	(  .run(1'b1),
		.miso(ADC_MISO[1]),
		//.mosi(),
		.sclk(ADC_SCLK[1]),
		.ss(ADC_CONV[1]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[1]), //syn to SCLK
		.DRDY() //  one SCLK period
	);
	
AD4001 adc_interface_2

	(  .run(1'b1),
		.miso(ADC_MISO[2]),
		//.mosi(),
		.sclk(ADC_SCLK[2]),
		.ss(ADC_CONV[2]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[2]), //syn to SCLK
		.DRDY() //  one SCLK period
	);
	
	
AD4001 adc_interface_3
	(  .run(1'b1),
		.miso(ADC_MISO[3]),
		//.mosi(),
		.sclk(ADC_SCLK[3]),
		.ss(ADC_CONV[3]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[3]), //syn to SCLK
		.DRDY() //  one SCLK period
	);


AD4001 adc_interface_4
	(  .run(1'b1),
		.miso(ADC_MISO[4]),
		//.mosi(),
		.sclk(ADC_SCLK[4]),
		.ss(ADC_CONV[4]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[4]), //syn to SCLK
		.DRDY() //  one SCLK period
	);

AD4001 adc_interface_5
	(  .run(1'b1),
		.miso(ADC_MISO[5]),
		//.mosi(),
		.sclk(ADC_SCLK[5]),
		.ss(ADC_CONV[5]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		
		.DOUT(ADC_INTERFACE_DOUT[5]), //syn to SCLK
		.DRDY() //  one SCLK period
	);	
AD4001 adc_interface_6
	(  .run(1'b1),
		.miso(ADC_MISO[6]),
		//.mosi(),
		.sclk(ADC_SCLK[6]),
		.ss(ADC_CONV[6]),
		.clk(CLK140M),
		.rst(SYS_RST),
		//.start_init(ADC_init_cmd), //init ADC
		//.start_read(ADC_read_cmd), //read ADC register
		//.conf_reg(ADC0_conf_reg),
		.DOUT(ADC_INTERFACE_DOUT[6]), //syn to SCLK
		.DRDY() //  one SCLK period
	);
	
always @ (posedge SCLK) if (ADC_data_valid) Ch_ADC_Reg <= ADC_INTERFACE_DOUT;

//I2C eeprom interface ////////////////////////////////////
parameter CONF_BUF_SIZE = 128; //max = 128 bytes for 24AA025E48T

reg  [7:0] configuration [CONF_BUF_SIZE-1:0]; //configuration data 
wire [7:0] eeprom_buffer [CONF_BUF_SIZE-1:0];

wire eeprom_busy,eeprom_data_valid;
wire rd_eeprom,wr_eeprom /*synthesis keep*/;

	I2C_eeprom eeprom_inst(
          .clk(SYS_CLK),   
          .rst(SYS_RST),
          .conf_data(configuration),
          .read(rd_eeprom),
          .write(wr_eeprom),
			 
			 .buffer(eeprom_buffer),
			 .busy(eeprom_busy),
			 .valid(eeprom_data_valid),

          .SDA(GPIO_1_8),
          .SCL(GPIO_1_6)               
                     );
							

							//================ Defining CPU to FPGA interface ===============
//Avalon Memory Mapped Slave Bus declariation	

wire avalon_read, avalon_write,avalon_cs/*synthesis keep*/;
wire [31:0] avalon_addr,avalon_readdata,avalon_writedata/*synthesis keep*/;

reg [31:0] dout;
assign avalon_readdata = dout;

parameter integer 	SR_ADDR = 0;
parameter integer 	CR_ADDR = 1;
parameter integer 	MR_ADDR = 2;

parameter integer    FPGA_VER_ADDR = 3;  //FPGA version # 
parameter integer 	CH_SELECT_ADDR = 4; //select channel for FIFO transfer to host 
parameter integer 	PCA_GAIN_ADDR = 5;

//parameter integer 	CHC_POWER_ADDR = 6;
parameter integer 	SFIFO_WD_ADDR = 7;
parameter integer 	SFIFO_ADDR = 8;

parameter integer 	FIFO_CLR_ADDR = 9;
parameter integer 	FIFO_WD_ADDR = 10;
parameter integer 	FIFO_ADDR = 11;

parameter integer 	TRIP_LEN_ADDR = 12;

parameter integer 	TRIP_CLR_ADDR = 13;
parameter integer 	TRIPCNT_CLR_ADDR = 14;

parameter integer 	EEPROM_RD_ADDR = 15;
parameter integer 	EEPROM_WR_ADDR = 16;


parameter integer 	CH0_ADDR = 20;
parameter integer 	CH1_ADDR = 21;
parameter integer 	CH2_ADDR = 22;
parameter integer 	CH3_ADDR = 23;
parameter integer 	CH4_ADDR = 24;
parameter integer 	CH5_ADDR = 25;
parameter integer 	CH6_ADDR = 26;
parameter integer 	CH7_ADDR = 27;

parameter integer 	TRIP_TH0_ADDR = 30;
parameter integer 	TRIP_TH1_ADDR = 31;
parameter integer 	TRIP_TH2_ADDR = 32;
parameter integer 	TRIP_TH3_ADDR = 33;
parameter integer 	TRIP_TH4_ADDR = 34;
parameter integer 	TRIP_TH5_ADDR = 35;
parameter integer 	TRIP_TH6_ADDR = 36;
parameter integer 	TRIP_TH7_ADDR = 37;

//parameter integer 	AVG_SHIFT_ADDR = 38;
parameter integer 	TRIP_TH8_ADDR = 38;
parameter integer 	TRIP_TH9_ADDR = 39;
parameter integer 	TRIP_TH10_ADDR = 40;
parameter integer 	TRIP_TH11_ADDR = 41;
parameter integer 	TRIP_TH12_ADDR = 42;
parameter integer 	TRIP_TH13_ADDR = 43;
parameter integer 	TRIP_TH14_ADDR = 44;
parameter integer 	TRIP_TH15_ADDR = 45;
	
//=======================================================
//=======================================================
soc_system u0(
               //Clock&Reset
               .clk_clk(FPGA_CLK1_50),                                      //                            clk.clk
               .reset_reset_n(hps_fpga_reset_n),                            //                          reset.reset_n
               //HPS ddr3
               .memory_mem_a(HPS_DDR3_ADDR),                                //                         memory.mem_a
               .memory_mem_ba(HPS_DDR3_BA),                                 //                               .mem_ba
               .memory_mem_ck(HPS_DDR3_CK_P),                               //                               .mem_ck
               .memory_mem_ck_n(HPS_DDR3_CK_N),                             //                               .mem_ck_n
               .memory_mem_cke(HPS_DDR3_CKE),                               //                               .mem_cke
               .memory_mem_cs_n(HPS_DDR3_CS_N),                             //                               .mem_cs_n
               .memory_mem_ras_n(HPS_DDR3_RAS_N),                           //                               .mem_ras_n
               .memory_mem_cas_n(HPS_DDR3_CAS_N),                           //                               .mem_cas_n
               .memory_mem_we_n(HPS_DDR3_WE_N),                             //                               .mem_we_n
               .memory_mem_reset_n(HPS_DDR3_RESET_N),                       //                               .mem_reset_n
               .memory_mem_dq(HPS_DDR3_DQ),                                 //                               .mem_dq
               .memory_mem_dqs(HPS_DDR3_DQS_P),                             //                               .mem_dqs
               .memory_mem_dqs_n(HPS_DDR3_DQS_N),                           //                               .mem_dqs_n
               .memory_mem_odt(HPS_DDR3_ODT),                               //                               .mem_odt
               .memory_mem_dm(HPS_DDR3_DM),                                 //                               .mem_dm
               .memory_oct_rzqin(HPS_DDR3_RZQ),                             //                               .oct_rzqin
               //HPS ethernet
               .hps_0_hps_io_hps_io_emac1_inst_TX_CLK(HPS_ENET_GTX_CLK),    //                   hps_0_hps_io.hps_io_emac1_inst_TX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_TXD0(HPS_ENET_TX_DATA[0]),   //                               .hps_io_emac1_inst_TXD0
               .hps_0_hps_io_hps_io_emac1_inst_TXD1(HPS_ENET_TX_DATA[1]),   //                               .hps_io_emac1_inst_TXD1
               .hps_0_hps_io_hps_io_emac1_inst_TXD2(HPS_ENET_TX_DATA[2]),   //                               .hps_io_emac1_inst_TXD2
               .hps_0_hps_io_hps_io_emac1_inst_TXD3(HPS_ENET_TX_DATA[3]),   //                               .hps_io_emac1_inst_TXD3
               .hps_0_hps_io_hps_io_emac1_inst_RXD0(HPS_ENET_RX_DATA[0]),   //                               .hps_io_emac1_inst_RXD0
               .hps_0_hps_io_hps_io_emac1_inst_MDIO(HPS_ENET_MDIO),         //                               .hps_io_emac1_inst_MDIO
               .hps_0_hps_io_hps_io_emac1_inst_MDC(HPS_ENET_MDC),           //                               .hps_io_emac1_inst_MDC
               .hps_0_hps_io_hps_io_emac1_inst_RX_CTL(HPS_ENET_RX_DV),      //                               .hps_io_emac1_inst_RX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_TX_CTL(HPS_ENET_TX_EN),      //                               .hps_io_emac1_inst_TX_CTL
               .hps_0_hps_io_hps_io_emac1_inst_RX_CLK(HPS_ENET_RX_CLK),     //                               .hps_io_emac1_inst_RX_CLK
               .hps_0_hps_io_hps_io_emac1_inst_RXD1(HPS_ENET_RX_DATA[1]),   //                               .hps_io_emac1_inst_RXD1
               .hps_0_hps_io_hps_io_emac1_inst_RXD2(HPS_ENET_RX_DATA[2]),   //                               .hps_io_emac1_inst_RXD2
               .hps_0_hps_io_hps_io_emac1_inst_RXD3(HPS_ENET_RX_DATA[3]),   //                               .hps_io_emac1_inst_RXD3
               //HPS SD card
               .hps_0_hps_io_hps_io_sdio_inst_CMD(HPS_SD_CMD),              //                               .hps_io_sdio_inst_CMD
               .hps_0_hps_io_hps_io_sdio_inst_D0(HPS_SD_DATA[0]),           //                               .hps_io_sdio_inst_D0
               .hps_0_hps_io_hps_io_sdio_inst_D1(HPS_SD_DATA[1]),           //                               .hps_io_sdio_inst_D1
               .hps_0_hps_io_hps_io_sdio_inst_CLK(HPS_SD_CLK),              //                               .hps_io_sdio_inst_CLK
               .hps_0_hps_io_hps_io_sdio_inst_D2(HPS_SD_DATA[2]),           //                               .hps_io_sdio_inst_D2
               .hps_0_hps_io_hps_io_sdio_inst_D3(HPS_SD_DATA[3]),           //                               .hps_io_sdio_inst_D3
               //HPS USB
               .hps_0_hps_io_hps_io_usb1_inst_D0(HPS_USB_DATA[0]),          //                               .hps_io_usb1_inst_D0
               .hps_0_hps_io_hps_io_usb1_inst_D1(HPS_USB_DATA[1]),          //                               .hps_io_usb1_inst_D1
               .hps_0_hps_io_hps_io_usb1_inst_D2(HPS_USB_DATA[2]),          //                               .hps_io_usb1_inst_D2
               .hps_0_hps_io_hps_io_usb1_inst_D3(HPS_USB_DATA[3]),          //                               .hps_io_usb1_inst_D3
               .hps_0_hps_io_hps_io_usb1_inst_D4(HPS_USB_DATA[4]),          //                               .hps_io_usb1_inst_D4
               .hps_0_hps_io_hps_io_usb1_inst_D5(HPS_USB_DATA[5]),          //                               .hps_io_usb1_inst_D5
               .hps_0_hps_io_hps_io_usb1_inst_D6(HPS_USB_DATA[6]),          //                               .hps_io_usb1_inst_D6
               .hps_0_hps_io_hps_io_usb1_inst_D7(HPS_USB_DATA[7]),          //                               .hps_io_usb1_inst_D7
               .hps_0_hps_io_hps_io_usb1_inst_CLK(HPS_USB_CLKOUT),          //                               .hps_io_usb1_inst_CLK
               .hps_0_hps_io_hps_io_usb1_inst_STP(HPS_USB_STP),             //                               .hps_io_usb1_inst_STP
               .hps_0_hps_io_hps_io_usb1_inst_DIR(HPS_USB_DIR),             //                               .hps_io_usb1_inst_DIR
               .hps_0_hps_io_hps_io_usb1_inst_NXT(HPS_USB_NXT),             //                               .hps_io_usb1_inst_NXT
               //HPS SPI
               .hps_0_hps_io_hps_io_spim1_inst_CLK(HPS_SPIM_CLK),           //                               .hps_io_spim1_inst_CLK
               .hps_0_hps_io_hps_io_spim1_inst_MOSI(HPS_SPIM_MOSI),         //                               .hps_io_spim1_inst_MOSI
               .hps_0_hps_io_hps_io_spim1_inst_MISO(HPS_SPIM_MISO),         //                               .hps_io_spim1_inst_MISO
               .hps_0_hps_io_hps_io_spim1_inst_SS0(HPS_SPIM_SS),            //                               .hps_io_spim1_inst_SS0
               //HPS UART
               .hps_0_hps_io_hps_io_uart0_inst_RX(HPS_UART_RX),             //                               .hps_io_uart0_inst_RX
               .hps_0_hps_io_hps_io_uart0_inst_TX(HPS_UART_TX),             //                               .hps_io_uart0_inst_TX
               //HPS I2C1
               .hps_0_hps_io_hps_io_i2c0_inst_SDA(HPS_I2C0_SDAT),           //                               .hps_io_i2c0_inst_SDA
               .hps_0_hps_io_hps_io_i2c0_inst_SCL(HPS_I2C0_SCLK),           //                               .hps_io_i2c0_inst_SCL
               //HPS I2C2
               .hps_0_hps_io_hps_io_i2c1_inst_SDA(HPS_I2C1_SDAT),           //                               .hps_io_i2c1_inst_SDA
               .hps_0_hps_io_hps_io_i2c1_inst_SCL(HPS_I2C1_SCLK),           //                               .hps_io_i2c1_inst_SCL
               //GPIO
               .hps_0_hps_io_hps_io_gpio_inst_GPIO09(HPS_CONV_USB_N),       //                               .hps_io_gpio_inst_GPIO09
               .hps_0_hps_io_hps_io_gpio_inst_GPIO35(HPS_ENET_INT_N),       //                               .hps_io_gpio_inst_GPIO35
               .hps_0_hps_io_hps_io_gpio_inst_GPIO40(HPS_LTC_GPIO),         //                               .hps_io_gpio_inst_GPIO40
               .hps_0_hps_io_hps_io_gpio_inst_GPIO53(HPS_LED),              //                               .hps_io_gpio_inst_GPIO53
               .hps_0_hps_io_hps_io_gpio_inst_GPIO54(HPS_KEY),              //                               .hps_io_gpio_inst_GPIO54
               .hps_0_hps_io_hps_io_gpio_inst_GPIO61(HPS_GSENSOR_INT),      //                               .hps_io_gpio_inst_GPIO61
               //FPGA Partion
               .led_pio_external_connection_export(fpga_led_internal),      //    led_pio_external_connection.export
               .dipsw_pio_external_connection_export(SW),                   //  dipsw_pio_external_connection.export
               .button_pio_external_connection_export(fpga_debounced_buttons),
                                                                            // button_pio_external_connection.export
               //.hps_0_h2f_reset_reset_n(hps_fpga_reset_n),                  //                hps_0_h2f_reset.reset_n
               
					.hps_0_f2h_cold_reset_req_reset_n(~Cold_Reset_Req),          //       hps_0_f2h_cold_reset_req.reset_n
               .hps_0_f2h_debug_reset_req_reset_n(~hps_debug_reset),        //      hps_0_f2h_debug_reset_req.reset_n
               .hps_0_f2h_stm_hw_events_stm_hwevents(stm_hw_events),        //        hps_0_f2h_stm_hw_events.stm_hwevents
               .hps_0_f2h_warm_reset_req_reset_n(~hps_warm_reset),          //       hps_0_f2h_warm_reset_req.reset_n
									                      
					.myavalonbus32_0_conduit_end_addr       (avalon_addr),       //myavalonbus32_0_avalon_slave.address
					.myavalonbus32_0_conduit_end_read       (avalon_read),      // .read
					.myavalonbus32_0_conduit_end_write      (avalon_write),     // .write
					.myavalonbus32_0_conduit_end_readdata   (avalon_readdata),   // .readdata
					.myavalonbus32_0_conduit_end_writedata  (avalon_writedata), // .writedata
					.myavalonbus32_0_conduit_end_cs 			 (avalon_cs),        // .chipselect
					.myavalonbus32_0_conduit_end_bus_clk    ()           //  myavalonbus32_0_clk.clk
		
				
           );

//Avalon Bus interface 	
reg [15:0] ch_reg = 0;	

wire run = `CON_REG_L8[0];
wire ena_dht = `CON_REG_L8[2];
assign self_chk = `CON_REG_L8[3];

wire [2:0] ch_select = ch_reg[2:0];

assign pca_gain = `PCA_GAIN_BIT_L8[1:0];

reg fifo_clr_reg; //needs to reset by itself after one SYS_CLK
reg trip_clr_reg; //needs to be reset by itself after one SYS_CLK
reg tripcnt_clr_reg; //1 clk wide as above

wire avalon_write_i = avalon_write & avalon_cs;
wire avalon_read_i = avalon_read & avalon_cs;

reg avalon_write_o,avalon_read_o /*synthesis keep*/;
wire fifo_rd /*synthesis keep*/;
assign fifo_rd = (avalon_addr == FIFO_ADDR & (avalon_read_i == 1));

wire [SFIFO_WIDTH-1:0] slow_fifo_dout;
wire sfifo_rd /*synthesis keep*/;
assign sfifo_rd = (avalon_addr == SFIFO_ADDR & (avalon_read_i == 1)); 


assign rd_eeprom = (avalon_addr == EEPROM_RD_ADDR & (avalon_write_o == 1)); //load eeprom -> buffer
assign wr_eeprom = (avalon_addr == EEPROM_WR_ADDR & (avalon_write_o == 1));//write buffer -> eeprom

always @ (posedge SYS_CLK)
     avalon_write_o <= avalon_write_i;
	  
always @ (posedge SYS_CLK)
     avalon_read_o <= avalon_read_i;	  

////////////////////////////////////////////////////////////////////////////	  
//Registers and Configuration data write/read  
	  
always@(posedge SYS_CLK)
	if (~eeprom_busy && eeprom_data_valid) 
				configuration <= eeprom_buffer; 
	else begin
   /*   Write to Control Register   */
	if ((avalon_addr == CR_ADDR) & (avalon_write_o == 1) ) 
			{`CON_REG_H8,`CON_REG_L8} <= avalon_writedata[15:0]; 	
	/*   Write to ch_select Register   */
	if ((avalon_addr == CH_SELECT_ADDR) & (avalon_write_o == 1) ) 
			ch_reg <= avalon_writedata[15:0]; 	
			
	/*   Read from Control Register   */		
	if ((avalon_addr == CR_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`CON_REG_H8,`CON_REG_L8}; 
	
	/*   Read from iStatus Register   */		
	if ((avalon_addr == SR_ADDR) & (avalon_read_o == 1) ) 
			dout <= interlock_status;
			
   /*   Read FPGA version   */		
	if ((avalon_addr == FPGA_VER_ADDR) & (avalon_read_o == 1)) 
			dout <= FPGA_VERSION_NO; 

	/*   Write to Mask Register   */
	if ((avalon_addr == MR_ADDR) & (avalon_write_o == 1) ) 
			{`MASK_REG_H8,`MASK_REG_L8} <= avalon_writedata[15:0]; 	

   /*   Read Mask Register  */		
	if ((avalon_addr == MR_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,`MASK_REG_H8,`MASK_REG_L8}; 			

	/*   Write to TRIP_LEN Register   */
	if ((avalon_addr == TRIP_LEN_ADDR) & (avalon_write_o == 1) ) 
			{`MASK_REG_H8,`MASK_REG_L8} <= avalon_writedata[15:0]; 	

   /*   ReadTRIP_LENMask Register  */		
	if ((avalon_addr == TRIP_LEN_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,`MASK_REG_H8,`MASK_REG_L8}; 		
			
	
	/*   slow fifo occupancy     */		
	if ((avalon_addr == SFIFO_WD_ADDR) & (avalon_read_o == 1)) 
			begin comm_act <= ~comm_act; dout <= {16'b0,8'b0,sfifo_rd_wd}; end
	

	/*   Read slow fifo     */		
	if ((avalon_addr == SFIFO_ADDR) & (avalon_read_o == 1)) 
			dout <= slow_fifo_dout; 	
	
	
	/*   Reset fast fifo     */		
	if ((avalon_addr == FIFO_CLR_ADDR) & (avalon_write_o == 1)) 
			fifo_clr_reg <= 1; 
	else fifo_clr_reg <= 0; 

	/*   Clear Trip      */		
	if ((avalon_addr == TRIP_CLR_ADDR) & (avalon_write_o == 1)) 
			trip_clr_reg <= 1; 
	else trip_clr_reg <= 0;
	
	/*   Clear Trip cnt and bits     */		
	if ((avalon_addr == TRIPCNT_CLR_ADDR) & (avalon_write_o == 1)) 
			tripcnt_clr_reg <= 1; 
	else tripcnt_clr_reg <= 0; 
	
	/*   Read fast fifo occupancy    */		
	if ((avalon_addr == FIFO_WD_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,3'b0,fifo_word}; 
			
	/*   Read fast fifo   */		
	if ((avalon_addr == FIFO_ADDR) & (avalon_read_o == 1)) 
			dout <= {16'b0,fast_fifo_dout}; 	
	
   /*   Write to Mini-PCA Gain bits   */
	if ((avalon_addr == PCA_GAIN_ADDR) & (avalon_write_o == 1) ) 
			{`PCA_GAIN_BIT_H8,`PCA_GAIN_BIT_L8} <= avalon_writedata[15:0]; 
		
	/*   Read from Mini-PCA Gain Register   */
	if ((avalon_addr == PCA_GAIN_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`PCA_GAIN_BIT_H8,`PCA_GAIN_BIT_L8};  	

	
   /*   Write/Read to Thresh 0  */
	if ((avalon_addr == TRIP_TH0_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH0 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH0_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH0};  

   /*   Write/Read to Thresh 1  */
	if ((avalon_addr == TRIP_TH1_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH1 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH1_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH1};  
			
   /*   Write/Read to Thresh 2  */
	if ((avalon_addr == TRIP_TH2_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH2 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH2_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH2};  

   /*   Write/Read to Thresh 3 */
	if ((avalon_addr == TRIP_TH3_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH3 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH3_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH3};  

   /*   Write/Read to Thresh 4  */
	if ((avalon_addr == TRIP_TH4_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH4 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH4_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH4};  

   /*   Write/Read to Thresh 5  */
	if ((avalon_addr == TRIP_TH5_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH5 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH5_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH5};  

   /*   Write/Read to Thresh 6  */
	if ((avalon_addr == TRIP_TH6_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH6 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH6_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH6};  

   /*   Write/Read to Thresh 7  */
	if ((avalon_addr == TRIP_TH7_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH7 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH7_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH7};  

   /*   Write/Read to Thresh 8  */
	if ((avalon_addr == TRIP_TH8_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH8 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH8_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH8};  

   /*   Write/Read to Thresh 9  */
	if ((avalon_addr == TRIP_TH9_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH9 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH9_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH9};  

   /*   Write/Read to Thresh 10  */
	if ((avalon_addr == TRIP_TH10_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH10 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH10_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH10};  

   /*   Write/Read to Thresh 11  */
	if ((avalon_addr == TRIP_TH11_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH11 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH11_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH11};  

   /*   Write/Read to Thresh 12  */
	if ((avalon_addr == TRIP_TH12_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH12 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH12_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH12};  

   /*   Write/Read to Thresh 13  */
	if ((avalon_addr == TRIP_TH13_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH13 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH13_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH13};  

   /*   Write/Read to Thresh 14  */
	if ((avalon_addr == TRIP_TH14_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH14 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH14_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH14};  

   /*   Write/Read to Thresh 15  */
	if ((avalon_addr == TRIP_TH15_ADDR) & (avalon_write_o == 1) ) 
			`TRIP_TH15 <= avalon_writedata[15:0]; 
	if ((avalon_addr == TRIP_TH15_ADDR) & (avalon_read_o == 1) ) 
			dout <= {16'b0,`TRIP_TH15};  			
end
		
		
////////////////////////////////////////////////////////////
//Fast FIFO to transfer ADC rate data from FPGA to SoC
	
	wire fast_FIFO_rst = SYS_RST | fifo_clr_reg;
   wire fifo_wr /*synthesis keep*/;
	
	wire fast_fifo_full, fast_fifo_empty;
		
	wire [ADC_DATA_WIDTH-1:0] din;
   assign din	= (ch_select == 3'b000)? ADC_INTERFACE_DOUT[0]
					: (ch_select == 3'b001)? ADC_INTERFACE_DOUT[1]
					: (ch_select == 3'b010)? ADC_INTERFACE_DOUT[2]
					: (ch_select == 3'b011)? ADC_INTERFACE_DOUT[3]
					: (ch_select == 3'b100)? ADC_INTERFACE_DOUT[4]
					: (ch_select == 3'b101)? ADC_INTERFACE_DOUT[5]
					: (ch_select == 3'b110)? ADC_INTERFACE_DOUT[6]
					: (ch_select == 3'b111)? ADC_INTERFACE_DOUT[7]
					: 16'b0;
	
	wire [ADC_DATA_WIDTH-1:0] fast_fifo_dout;
	wire [12:0] fifo_word /*synthesis keep*/;
		
	fifo4096 Fast_FIFO (
		.aclr(fast_FIFO_rst), //
		.wrclk(SCLK), //
		.rdclk(SYS_CLK), //
		.data(din), // input [15 : 0] din
		.wrreq(fifo_wr), //
		.rdreq(fifo_rd),
		.q(fast_fifo_dout), // output [15 : 0] dout
		.rdfull(fast_fifo_full), //
		.rdempty(fast_fifo_empty),
		.wrusedw(fifo_word) //
	);
	
	fifo_control fifo_control_inst(
		.RUN(1'b1),
		.rst(SYS_RST),
		.clk(SCLK),

      .fifo_full(fast_fifo_full),
		.fifo_empty(fast_fifo_empty),
		.data_valid(ADC_data_valid), //input from ADC interface
		
		.wr(fifo_wr), // output, write Fast fifo
	
		.busy(busy) // output, not in use
	);
	
//================ processing ==============
	
wire processing_done;
wire signed[31:0] Ch_I_value[7:0];
wire [15:0] I_value[7:0];

wire signed [15:0] I_beam[7:0];
 
calc_current cal_i_ins(
	.Data_In(Ch_ADC_Reg),
	.Data_In_Valid(ADC_data_valid), //one clk wide, freq = ADC sampling freq, 10 KHz ~ 100 KHz
	.gain(pca_gain),
	.avg_shift(0),
	.is_aete(IS_AETE),
	.clk(SCLK),  
	.rst(SYS_RST),

	.I_avg(Ch_I_value), //signed 32bit, in pA
	.I_beam(I_beam), //signed 16 bit, in mV, ADC input voltage.
	.RDY(processing_done)	
    );
	 
///================ Slow FIFO ===================

	reg sFIFO_wr;
	reg [SFIFO_WIDTH-1:0] sfifo_data_in;
	wire [7:0] sfifo_rd_wd,sfifo_wr_wd;
	wire sfifo_half_full = sfifo_wr_wd[6]; // 64   
	
	slfifo Slow_FIFO (
		.aclr(SYS_RST),
		.data(sfifo_data_in),
		.wrclk(SCLK),
		.rdclk(SYS_CLK),
		.wrreq(sFIFO_wr),
		.rdreq(sfifo_rd),
		.q(slow_fifo_dout),
		.rdusedw(sfifo_rd_wd), 
		.wrusedw(sfifo_wr_wd)
	);  
//	output [7:0]  rdusedw;
//	output [7:0]  wrusedw;
// slfifo is 128 words(32bit) deep, Nov.29,2018
	
//============Packing=================================
	parameter PID = 32'h4142504d; // "ABPM"
	//parameter EID = 32'h4242504E; // "BBPN"

	reg [7:0] p_state;

//data packet size is 32 words (32bit)
	always @(posedge SCLK)
	begin
		if(SYS_RST)
			begin
				p_state <= 0;
				sFIFO_wr<= 0;
			end

		else
			begin
				case(p_state)
					0:if(processing_done && !sfifo_half_full)
						begin  sFIFO_wr<= 1; sfifo_data_in <= PID; p_state <= 1; end
					1: begin sfifo_data_in <= {`CON_REG_H8,`CON_REG_L8,`MASK_REG_H8,`MASK_REG_L8}; p_state <= 2; end
					2: begin sfifo_data_in <= 0; p_state <= 3; end
					3: begin sfifo_data_in <= interlock_status; p_state <= 4; end			
					4: begin sfifo_data_in <= {analog_readback[0],analog_readback[1]}; p_state <= 5; end
					5: begin sfifo_data_in <= {analog_readback[2],analog_readback[3]}; p_state <= 6; end
					6: begin sfifo_data_in <= {analog_readback[4],analog_readback[5]}; p_state <= 7; end
					7: begin sfifo_data_in <= {analog_readback[6],analog_readback[7]}; p_state <= 8; end
					8: begin sfifo_data_in <= {analog_readback[8],analog_readback[9]}; p_state <= 9; end
					9: begin sfifo_data_in <= {analog_readback[10],analog_readback[11]}; p_state <= 10; end
					10: begin sfifo_data_in <= {analog_readback[12],analog_readback[13]}; p_state <= 11; end
					11: begin sfifo_data_in <= {analog_readback[14],analog_readback[15]}; p_state <= 12; end			
					12: begin sfifo_data_in <= {trip_thresh[0],trip_thresh[1]}; p_state <= 13; end
					13: begin sfifo_data_in <= {trip_thresh[2],trip_thresh[3]}; p_state <= 14; end
					14: begin sfifo_data_in <= {trip_thresh[4],trip_thresh[5]}; p_state <= 15; end
					15: begin sfifo_data_in <= {trip_thresh[6],trip_thresh[7]}; p_state <= 16; end
					16: begin sfifo_data_in <= {trip_thresh[8],trip_thresh[9]}; p_state <= 17; end
					17: begin sfifo_data_in <= {trip_thresh[10],trip_thresh[11]}; p_state <= 18; end
					18: begin sfifo_data_in <= {trip_thresh[12],trip_thresh[13]}; p_state <= 19; end
					19: begin sfifo_data_in <= {trip_thresh[14],trip_thresh[15]}; p_state <= 20; end
					20: begin sfifo_data_in <= Ch_I_value[0]; p_state <= 21; end
					21: begin sfifo_data_in <= Ch_I_value[1]; p_state <= 22; end
					22: begin sfifo_data_in <= Ch_I_value[2]; p_state <= 23; end
					23: begin sfifo_data_in <= Ch_I_value[3]; p_state <= 24; end
					24: begin sfifo_data_in <= Ch_I_value[4]; p_state <= 25; end
					25: begin sfifo_data_in <= Ch_I_value[5]; p_state <= 26; end
					26: begin sfifo_data_in <= Ch_I_value[6]; p_state <= 27; end
					27: begin sfifo_data_in <= Ch_I_value[7]; p_state <= 28; end
					28: begin sfifo_data_in <= {trip_cnt[3],trip_cnt[2],trip_cnt[1],trip_cnt[0]}; p_state <= 29; end
					29: begin sfifo_data_in <= {trip_cnt[7],trip_cnt[6],trip_cnt[5],trip_cnt[4]}; p_state <= 30; end
					30: begin sfifo_data_in <= last_trip_bit; p_state <= 31; end
					31: begin sfifo_data_in <= {16'b0,8'b0,digi_in}; p_state <= 32; end
					32: begin sFIFO_wr<= 0; p_state <= 0; end
					default:
						begin sFIFO_wr<= 0; p_state <= 0; end
				endcase
			end

	end


///////////////////////////////////////////////////////////////////////////////////////////////////////////	
//Target protect logic
//Target protect logic : 
// input: 8 digital, 8 analog, 16 trip threshold;
// output: 16 analog (8 input + 8 derived value), 8 relay contact.
// note very important!!!
// the 16 bit current/threshold signal are in unit of 65.5 nA, 
// the HV threshold is also represented by current in which 1 uA = 100 V. 


//HV divider input channel has the conversion: 1 uA = 100 V, due to the 100 Mohm divider resistor of 0682-2 module


wire [15:0] analog_readback[15:0];  //for slow FIFO read back
wire [31:0] interlock_status; //for slow FIFO read back
wire interlock_fault; //to drive Fault LED only
wire [15:0] mask_bit = {`MASK_REG_H8,`MASK_REG_L8};
wire [31:0] last_trip_bit;
wire [7:0] trip_cnt[7:0];

wire clr_trip = trip_clr_reg;
wire clr_trip_cnt = tripcnt_clr_reg;	

wire clr_trip_resyn;

wire tripped;
assign OPT_out = OPT_in & ~tripped; // generate watchdog 5MHz output

pulse_stretcher pulse_stretch_inst(
    .clk(SYS_CLK),
    .pulse_in(clr_trip),    // input pulse (1 clock wide)
    .pulse_out(clr_trip_resyn)    // output pulse (9 clocks wide)
);

AETE_logic AETE_inst (
        .clk(SCLK),
        .rst(),
		  .data_valid(ADC_data_valid),
        .digi_in(digi_in),
        .mask(mask_bit),
        .clear_trip(clr_trip_resyn),
        .analog_in(Ch_I_value),
        .thresh(trip_thresh),
        .readback(analog_readback),
        .status(interlock_status),
        .tripped_reg(tripped)
);


//============ self test pulse ============

clockdiv squrewave(
	.clk(SYS_CLK),
	.enable(self_chk),
   .oclk(test_pulse) 
);
  defparam squrewave.CLK_PERIOD = 20;      // ns, clk period default 50 MHz
  defparam squrewave.CLK_OUT_PERIOD = 100000000; //ns, outptu clock period, default 10 Hz
  defparam squrewave.CNT_WIDTH = 32;   // 

//=========== DHT11 sensor ========================
//	 inout  GPIO_1_18, //Test 8 = DHT11 Sig


// REMOVE AFTER TESTING

//reg [15:0] temp, humi;
//
//dht11 temp_sensor(
//	.i_clk(SYS_CLK),
//	.i_rst_n(ena_dht),
//	.io_data(GPIO_1_18),
//	.o_temp(temp),
//	.o_humi(humi)
//	);


//========LED ============================
reg comm_act;
assign LED_COMM = comm_act;
flash_LED flash_led_inst(
    .clk(SCLK),  //10 MHz clock 
	 .led(LED_FPGA)
    );
	
	
// Debounce logic to clean out glitches within 1ms		
debounce debounce_inst(
             .clk(fpga_clk_50),
             .reset_n(hps_fpga_reset_n),
             .data_in(KEY),
             .data_out(fpga_debounced_buttons)
         );
defparam debounce_inst.WIDTH = 2;
defparam debounce_inst.POLARITY = "LOW";
defparam debounce_inst.TIMEOUT = 50000;               // at 50Mhz this is a debounce time of 1ms
defparam debounce_inst.TIMEOUT_WIDTH = 16;            // ceil(log2(TIMEOUT))

// Source/Probe megawizard instance
hps_reset hps_reset_inst(
              .source_clk(fpga_clk_50),
              .source(hps_reset_req)
          );

altera_edge_detector pulse_cold_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(Cold_Reset_Req),
                         .pulse_out(hps_cold_reset)
                     );
defparam pulse_cold_reset.PULSE_EXT = 6;
defparam pulse_cold_reset.EDGE_TYPE = 1;
defparam pulse_cold_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_warm_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[1]),
                         .pulse_out(hps_warm_reset)
                     );
defparam pulse_warm_reset.PULSE_EXT = 2;
defparam pulse_warm_reset.EDGE_TYPE = 1;
defparam pulse_warm_reset.IGNORE_RST_WHILE_BUSY = 1;

altera_edge_detector pulse_debug_reset(
                         .clk(fpga_clk_50),
                         .rst_n(hps_fpga_reset_n),
                         .signal_in(hps_reset_req[2]),
                         .pulse_out(hps_debug_reset)
                     );
defparam pulse_debug_reset.PULSE_EXT = 32;
defparam pulse_debug_reset.EDGE_TYPE = 1;
defparam pulse_debug_reset.IGNORE_RST_WHILE_BUSY = 1;


	
endmodule
