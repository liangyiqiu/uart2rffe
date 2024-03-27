module top
(
    input clk,

    input  FPGA_RX,
	output FPGA_TX,
    
    output spi_clk_rffe,
    output spi_sdo_rffe,
    output spi_le_rffe,

    output [1:0] led
);

wire rst_n;

rst rst(
    .clk(clk),
    .rst_n(rst_n)
);

parameter spi_data_depth_max = 54; //54 bits max spi transmition
parameter spi_clk_div = 5;  //spi clock=100M/5=20MHz

wire spi_start;
wire [1:0] spi_ready;
wire spi_dir;
wire [7:0] spi_data_depth;
wire [spi_data_depth_max-1:0] spi_data_tx;


spi_master_modify #(
    .clk_div(spi_clk_div),
    .data_depth(spi_data_depth_max)
)
rffe_spi(
    .clk(clk),
    .rst_n(rst_n),
    .spi_start(spi_start),
    .spi_dir(spi_dir),
    .spi_data_depth(spi_data_depth),
    .spi_data_tx(spi_data_tx),
    .spi_ready(spi_ready),
    .spi_sclk(spi_clk_rffe),
    .spi_mosi(spi_sdo_rffe),
    .spi_le(spi_le_rffe)
);

parameter  Baud_rate = 115200; 	
parameter  clk_frq = 50000000; //tx & rx frequency
parameter  data_depth = 12;  //tx & rx data buffer depth		

parameter  data_bits = 8;  		
parameter  stop_bits = 2'b00;  	
parameter  parity = 2'b00; 

wire [data_depth*8-1:0] send_data;
wire [5:0] send_data_bytes;
wire TX_ready;
wire start_TX;
wire TX_busy;

UART_TX #(
    .Baud_rate(Baud_rate),  
    .clk_frq(clk_frq), 	
    .data_depth(data_depth) 
) 
TX (  
    .clk(clk),             
    .rst(rst_n),             
    .data_bits(data_bits), 
    .stop_bits(stop_bits), 
    .parity(parity_bit),   
    .send_data(send_data), 
    .send_data_bytes(send_data_bytes),
    .TX_ready(TX_ready),                   
    .start_TX(start_TX),                  
    .TX(FPGA_TX)                         
); 
    

wire [data_depth*8-1:0] receive_data;
wire [data_depth*8-1:0] receive_data_;
// wire [5:0] receive_data_bytes;
wire [data_depth-1:0] receive_data_check;
wire receive_data_check_all;
wire RX_interrupt;
wire RX_interrupt_clear;
    
UART_RX #(
    .Baud_rate(Baud_rate),	 
    .clk_frq(clk_frq),  	 
    .data_depth(data_depth)
)
RX(
    .clk(clk),             								
    .rst(rst_n),             									
    .data_bits(data_bits), 									
    .stop_bits(stop_bits), 									
    .parity(parity),    										
    .receive_data(receive_data), 							
    .receive_data_(receive_data_), 							
    // .receive_data_bytes(receive_data_bytes),        	 
    .receive_data_check(receive_data_check), 			
    .receive_data_check_all(receive_data_check_all),	
    .RX_interrupt(RX_interrupt),               			
    .RX_interrupt_clear(RX_interrupt_clear),          
    .RX(FPGA_RX)                         					
);

process process(
    .clk(clk),             								
    .rst_n(rst_n),
    .tx_ready(TX_ready),
    .start_tx(start_TX),
    .send_data(send_data),
    .send_data_bytes(send_data_bytes),
    .RX_interrupt(RX_interrupt),               			
    .RX_interrupt_clear(RX_interrupt_clear), 
    .receive_data(receive_data), 
    // .receive_data_bytes(receive_data_bytes),
    .spi_ready(spi_ready),
    .spi_dir(spi_dir),
    .spi_start(spi_start),
    .spi_data_tx(spi_data_tx),
    .spi_data_depth(spi_data_depth)
);

endmodule