`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:40:34 05/02/2022
// Design Name:   process
// Module Name:   C:/Users/85038/Desktop/MWC01/sim/tb_process.v
// Project Name:  mwc01
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: process
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_process;

	// Inputs
	reg clk_100M;
	reg rst_n;
	reg tx_ready;
	reg [87:0] receive_data;
	reg RX_interrupt;
	reg spi_ready;
	reg [431:0] spi_data_rx;
	reg spi_read_finish;

	// Outputs
	wire start_tx;
	wire [47:0] send_data;
	wire [3:0] send_data_bytes;
	wire [3:0] receive_data_bytes;
	wire RX_interrupt_clear;
	wire spi_dir;
	wire [7:0] spi_data_depth;
	wire spi_start;
	wire [13:0] spi_data_tx;
	
	// Instantiate the Unit Under Test (UUT)
	process uut (
        .clk(clk_100M),             								
        .rst_n(rst_n),
        .tx_ready(TX_ready),
        .start_tx(start_TX),
        .send_data(send_data),
        .send_data_bytes(send_data_bytes),
        .RX_interrupt(RX_interrupt),               			
        .RX_interrupt_clear(RX_interrupt_clear), 
        .receive_data(receive_data), 
        .receive_data_bytes(receive_data_bytes),
        .spi_ready(spi_ready),
        .spi_dir(spi_dir),
        .spi_start(spi_start),
        .spi_data_tx(spi_data_tx),
        .spi_data_depth(spi_data_depth)
    );

	initial begin
		// Initialize Inputs
		clk_100M = 0;
		rst_n = 0;
		tx_ready = 0;
		receive_data = 0;
		RX_interrupt = 0;
		spi_ready = 1;
		spi_data_rx = 0;

		// Wait 100 ns for global reset to finish
		#100;
        // Add stimulus here
		rst_n=1;	
		
		#100
		receive_data=88'h55_5D_01_AA_BB_BB_CC_DD_00_0d_0a;
		RX_interrupt=1;
		
		#100 
		spi_ready=1;
		
		#100 
		receive_data=88'h55_5D_02_00_AA_BB_CC_DD_dd_0d_0a;
		RX_interrupt=1;

	end
	always#5 clk_100M=~clk_100M;
	always @(posedge clk_100M)
	begin
		if(RX_interrupt_clear)
			RX_interrupt<=0;
		if(spi_start)
			spi_ready<=0;
	end
endmodule

