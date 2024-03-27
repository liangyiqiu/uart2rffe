`timescale 1ns / 1ps

module spi_master_modify #(
    parameter clk_div=10,
    parameter data_depth=32,
    parameter rx_head_depth=6
)
(
    input clk,
    input rst_n,
    input spi_start,
    input spi_dir, //write(0)|read(1)
    input [7:0] spi_data_depth,
    input spi_miso,
    input [data_depth-1:0] spi_data_tx,
    output reg [data_depth-1:0] spi_data_rx,
    output reg spi_ready,
    output reg spi_sclk,
    output reg spi_read_finish,//one spi-clock cirle pulse
    output reg spi_mosi,
    output reg spi_le
);

reg spi_dir_reg;
reg [data_depth-1:0] spi_data_tx_reg;
reg [2:0] spi_state;
reg [7:0] spi_bit_cnt;
reg [15:0] clk_div_cnt;

reg [1:0] spi_ssc_cnt;

localparam                  SPI_IDLE        = 0, 
                            SPI_SSC         = 1,
                            SPI_WRITE_CLOCK_HIGH  = 2, 
                            SPI_WRITE_CLOCK_LOW  = 3, 
                            SPI_READ_CLOCK_HIGH  = 4, 
                            SPI_READ_CLOCK_LOW  = 5;
always @(posedge clk)
begin
    if(!rst_n)
    begin
        spi_le<=1;
        spi_sclk<=0;
        spi_mosi<=0;
        spi_state<=SPI_IDLE;
        spi_ready<=1;
        spi_read_finish<=0;
        spi_bit_cnt<=0;
        spi_ssc_cnt<=2'd0;
    end
    else if(spi_ready)//idle
    begin
        if(spi_start)
        begin
            spi_ready<=0;
            spi_le<=0;
            spi_dir_reg<=spi_dir;
            spi_data_tx_reg<=spi_data_tx;
            spi_ssc_cnt<=2'd0;
            spi_state<=SPI_SSC;
        end
    end
    else//busy
    begin
        if(clk_div_cnt!=clk_div-1)
            clk_div_cnt<=clk_div_cnt+1'b1;
        else
        begin
            clk_div_cnt<=0;
            case(spi_state)
            SPI_IDLE:
            begin
                spi_ready<=1;
                spi_le<=1;
                spi_read_finish<=0;
                spi_bit_cnt<=0;
                spi_sclk<=0;
                spi_mosi<=0;
                spi_state<=SPI_IDLE;
            end

            SPI_SSC:
            begin
                spi_sclk<=0;
                if(spi_ssc_cnt==2'd3)
                begin
                    spi_mosi <= 1'd0;
                    spi_ssc_cnt <= 2'd0;      
                    spi_state<=SPI_WRITE_CLOCK_HIGH;          
                end
                else
                if(spi_ssc_cnt==2'd2)
                begin
                    spi_mosi <= 1'd0;
                    spi_ssc_cnt <= spi_ssc_cnt+1'd1;     
                    spi_state<=SPI_SSC;            
                end
                else
                begin
                    spi_mosi <= 1'd1;
                    spi_ssc_cnt <= spi_ssc_cnt+1'd1;     
                    spi_state<=SPI_SSC;              
                end
            end

            SPI_WRITE_CLOCK_HIGH:
            begin
                spi_sclk<=1;
                spi_mosi<=spi_data_tx_reg[spi_data_depth-spi_bit_cnt-1];
                spi_state<=SPI_WRITE_CLOCK_LOW;
            end

            SPI_WRITE_CLOCK_LOW:
            begin
                spi_bit_cnt<=spi_bit_cnt+1'b1;

                spi_sclk<=1'b0;

                if(spi_dir_reg)//rx
                    if(spi_bit_cnt==rx_head_depth-1)
                        spi_state<=SPI_READ_CLOCK_HIGH;
                    else
                        spi_state<=SPI_WRITE_CLOCK_HIGH;
                else//tx
                    if(spi_bit_cnt==spi_data_depth-1)//tx finish
                    begin
                        spi_state<=SPI_IDLE;
                    end
                    else
                        spi_state<=SPI_WRITE_CLOCK_HIGH;
            end

            SPI_READ_CLOCK_HIGH:
            begin
                spi_sclk<=1;
                spi_state<=SPI_READ_CLOCK_LOW;
            end

            SPI_READ_CLOCK_LOW:
            begin
                spi_bit_cnt<=spi_bit_cnt+1'b1;

                spi_sclk<=1'b0;
					
                spi_data_rx[spi_data_depth-spi_bit_cnt-1]<=spi_miso;

                if(spi_bit_cnt==spi_data_depth-1)//rx finish
                begin
                    spi_state<=SPI_IDLE;
                    spi_read_finish<=1;
                end
                else
                    spi_state<=SPI_READ_CLOCK_HIGH;
            end

            endcase
        end
    end
end

endmodule