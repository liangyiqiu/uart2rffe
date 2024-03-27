`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:44:26 05/03/2022
// Design Name:   top
// Module Name:   C:/Users/85038/Desktop/MWC01/sim/tb_top.v
// Project Name:  mwc01
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_top;

	// Inputs
	reg clk_in;
	reg [3:0] dip;
	reg FPGA_RX;

	// Outputs
	wire FPGA_TX;
	wire [1:0] led;
	wire spi_clk_rffe;
	wire spi_sdo_rffe;
	wire spi_le_rffe;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk(clk_in), 
		.FPGA_RX(FPGA_RX), 
		.FPGA_TX(FPGA_TX), 
		.spi_clk_rffe(spi_clk_rffe),
		.spi_sdo_rffe(spi_sdo_rffe),
		.spi_le_rffe(spi_le_rffe),
		.led(led)
	);

	integer bitTime, idx, idxWord, idxBit;
	reg [7:0] word [0:10];

	initial begin
		// Initialize Inputs
		clk_in = 0;
		dip = 0;
		FPGA_RX = 0;

		// Wait 100 ns for global reset to finish
		#100

		// Add stimulus here
		bitTime = 8680;  // ���ݲ���������λʱ������
		word[0] = 8'h55;
		word[1] = 8'h5D;
		word[2] = 8'h01;
		word[3] = 8'h2a;
		word[4] = 8'hfc;
		word[5] = 8'h00;
		word[6] = 8'h00;
		word[7] = 8'h01;
		word[8] = 8'h02;
		word[9] = 8'h0d;
		word[10] = 8'h0a;

		for (idxWord=0; idxWord<11; idxWord=idxWord+1) begin  // �����ֽ�
			FPGA_RX = 1'b0; #bitTime; //start
			for (idxBit=0; idxBit<8; idxBit=idxBit+1) begin  // ����λ
				FPGA_RX = word[idxWord][idxBit];
				#bitTime;
			end
			FPGA_RX = 1'b1; #bitTime; //stop
		end
		
		// #(bitTime*8);
		
		// word[0] = 8'h55;
		// word[1] = 8'h5D;
		// word[2] = 8'h4a;
		// word[3] = 8'h02;
		// word[4] = 8'h0a;
		// word[5] = 8'hbb;
		// word[6] = 8'hcc;
		// word[7] = 8'hdd;
		// word[8] = 8'hee;
		// word[9] = 8'h0d;
		// word[10] = 8'h0a;

		// for (idxWord=0; idxWord<11; idxWord=idxWord+1) begin  // �����ֽ�
		// 	FPGA_RX = 1'b0; #bitTime; //start
		// 	for (idxBit=0; idxBit<8; idxBit=idxBit+1) begin  // ����λ
		// 		FPGA_RX = word[idxWord][idxBit];
		// 		#bitTime;
		// 	end
		// 	FPGA_RX = 1'b1; #bitTime; //stop
		// end
		

		// #(bitTime*8);

		// word[0] = 8'h55;
		// word[1] = 8'h5D;
		// word[2] = 8'h01;
		// word[3] = 8'h00;
		// word[4] = 8'h00;
		// word[5] = 8'h00;
		// word[6] = 8'h00;
		// word[7] = 8'h04;
		// word[8] = 8'haa;
		// word[9] = 8'h0d;
		// word[10] = 8'h0a;


		// for (idxWord=0; idxWord<11; idxWord=idxWord+1) begin  // �����ֽ�
		// 	FPGA_RX = 1'b0; #bitTime; //start
		// 	for (idxBit=0; idxBit<8; idxBit=idxBit+1) begin  // ����λ
		// 		FPGA_RX = word[idxWord][idxBit];
		// 		#bitTime;
		// 	end
		// 	FPGA_RX = 1'b1; #bitTime; //stop
		// end
		
		#(bitTime*8);

		word[0] = 8'h55;
		word[1] = 8'h5D;
		word[2] = 8'haa;
		word[3] = 8'h00;
		word[4] = 8'h00;
		word[5] = 8'h00;
		word[6] = 8'h00;
		word[7] = 8'h01;
		word[8] = 8'haa;
		word[9] = 8'h0d;
		word[10] = 8'h0a;


		for (idxWord=0; idxWord<11; idxWord=idxWord+1) begin  // �����ֽ�
			FPGA_RX = 1'b0; #bitTime; //start
			for (idxBit=0; idxBit<8; idxBit=idxBit+1) begin  // ����λ
				FPGA_RX = word[idxWord][idxBit];
				#bitTime;
			end
			FPGA_RX = 1'b1; #bitTime; //stop
		end
    end
    always#10 clk_in=~clk_in;
endmodule

