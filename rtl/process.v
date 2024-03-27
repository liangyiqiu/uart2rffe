module process
#(
    parameter uart_data_depth = 12
)
(
	input clk,
	input rst_n,

    input tx_ready,
	output reg start_tx,
	output reg [uart_data_depth*8-1:0] send_data,
	output reg [5:0] send_data_bytes,

	input [uart_data_depth*8-1:0] receive_data,
	input RX_interrupt,
	// output reg [3:0] receive_data_bytes,
	output reg RX_interrupt_clear,

    input spi_ready,
    output reg spi_dir,
    output reg spi_start,
    output reg [23:0] spi_data_tx,
    output reg [7:0] spi_data_depth
);

localparam              PROCESS_RESET    = 0, 
                        UART_DEBUG       = 1;

wire [7:0] rx_byte [uart_data_depth-1:0];

genvar i;
generate 
    for(i=1;i<=uart_data_depth;i=i+1) 
    begin: rx_byte_gen
        assign rx_byte[i-1][7:0]=receive_data[i*8-1-:8];
    end
endgenerate

reg [1:0] process_state=PROCESS_RESET;
reg spi_wait;

always @(posedge clk)
case(process_state)
PROCESS_RESET:
begin
    RX_interrupt_clear<=0;
    spi_start<=0;
    // receive_data_bytes<=2;
    spi_wait<=0;
    if(rst_n)
        process_state<=UART_DEBUG;   
end
UART_DEBUG:
begin
    if(RX_interrupt)
    begin
        if((rx_byte[10] == 8'h55) && (rx_byte[9] == 8'h5D) 
        && (rx_byte[1] == 8'h0D) && (rx_byte[0] == 8'h0A)) //'head' and 'end' check 
        begin
            case(rx_byte[8])
            8'h01: // write rffe reg0
            begin
                spi_dir<=0;
                spi_data_depth<=14;
                spi_data_tx<={rx_byte[7],rx_byte[6]};
                spi_start<=1;   
            end
            8'h02: // write rffe
            begin
                spi_dir<=0;
                spi_data_depth<=23;
                spi_data_tx<={rx_byte[7],rx_byte[6],rx_byte[5]};
                spi_start<=1;   
            end
            8'hAA:// uart connection test
            begin
                send_data<= 80'h45504741204F4B210D0A;// FPGA OK!
                send_data_bytes<=10;
                start_tx<=1;
            end
            endcase
        end
        else
        begin
            send_data<= 64'h6572726F72210D0A; //'error!'
            send_data_bytes<=8;
            start_tx<=1;
        end
        RX_interrupt_clear<=1;
    end
    else
    begin
        spi_start<=0;
        RX_interrupt_clear<=0;
        start_tx<=0;
    end 

    if(spi_wait&&spi_ready) //a spi transmition is waiting to start
    begin
        spi_wait<=0;
        spi_start<=1;
    end   
end
endcase

endmodule
