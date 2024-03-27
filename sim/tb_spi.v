`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:51:43 04/29/2022
// Design Name:   spi_master
// Module Name:   C:/Users/85038/Desktop/MWC01/sim/tb_spi.v
// Project Name:  mwc01
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: spi_master
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_spi;

	// Inputs
	reg clk;
	reg rst_n;
	reg spi_start;
	reg spi_dir;
	reg spi_miso;
	reg [31:0] spi_data_tx;
	reg [7:0] rx_byte;
	reg [15:0] spi_data_depth;
	

	// Outputs
	wire [31:0] spi_data_rx;
	wire spi_ready;
	wire spi_sclk;
	wire spi_mosi;
	wire spi_read_finish;
	wire spi_le;

	// Instantiate the Unit Under Test (UUT)
	spi_master_modify uut (
		.clk(clk), 
		.rst_n(rst_n), 
		.spi_start(spi_start), 
		.spi_dir(spi_dir), 
		.spi_miso(spi_miso), 
		.spi_data_tx(spi_data_tx), 
		.spi_data_rx(spi_data_rx), 
		.spi_ready(spi_ready), 
		.spi_sclk(spi_sclk), 
		.spi_mosi(spi_mosi),
		.spi_read_finish(spi_read_finish),
		.spi_data_depth(spi_data_depth),
		.spi_le(spi_le)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst_n = 0;
		spi_start = 0;
		spi_dir = 0;
		spi_data_tx = 0;
		spi_miso=1'b1;
		rx_byte=8'haa;

		// Wait 100 ns for global reset to finish
		#100
		rst_n=1;
		#100
		spi_data_tx={4{rx_byte}};
		spi_data_depth=14;
		spi_dir=0;
		spi_start=1;
		#100
		spi_start=0;
		
		// #5000
		// spi_dir=1;
		// spi_data_depth=48;
		// spi_data_tx={9{16'haa_cc,32'b0}};
		// spi_start=1;
		// #10
		// spi_start=0;

	end
	always#5 clk=~clk;
        
		// Add stimulus here
      
endmodule

