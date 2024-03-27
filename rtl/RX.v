`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU_MMW
// Engineer: XXQ
// 
// Create Date:    10:23:40 07/20/2020 
// Design Name: 
// Module Name:    UART_RX 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 串口接收程序，通过多倍过采样来确定串口数据，程序内部包含了去除亚稳态及毛刺，支持多种速率的串口以及支持各种数据格式，停止位格式，支持奇偶校验。
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module UART_RX #(
parameter  Baud_rate = 115200, //默认波特率=9600  支持 4800 9600 19200 57600 115200 230400 460800 921600 
parameter  clk_frq = 100000000,  //默认时钟频率100MHz 请大于100MHz 并且小于250MHz
parameter  data_depth = 36  //默认数据深度为36，单次支持最大data_depth的接收和发送 建议最大不超过63，如果超过63，请改变下面的 send_data_bytes和receive_data_bytes
) 
(
    
    input  wire clk,             //总体时钟 与clk_frq相匹配
    input  wire rst,             //复位，低电平复位
    
    input  wire [3:0] data_bits, //数据bit 支持5 6 7 8 位
    input  wire [1:0] stop_bits, //停止位，00=1位停止位，01=1.5位停止位，10=2位停止位
    input  wire [1:0] parity,    //校验位，00=无校验位， 01=偶校，10=奇校验
     
    output reg  [data_depth*8-1:0] receive_data, //接收的数据  数据靠近低位   00_00_……00_XX_XX_XX  (XX为有效数据，高位为第一个字节)
	 output reg  [data_depth*8-1:0] receive_data_, //接收的数据  数据靠近高位  XX_XX_XX_00_00_……00  (XX为有效数据，高位为第一个字节)
    output reg  [5:0] receive_data_bytes,        //接收的数据的字节数  
    output reg  [data_depth-1:0] receive_data_check, //接收的数据是否满足奇偶校验（如果启用了奇偶校验功能，1表示正确数据，0表示不正确数据），每个bit表征该字节的正确度
	 output reg  receive_data_check_all, //接收的数据串正确度 1表示正确，0表示错误
    
    output reg  RX_interrupt,               //接收完一次的中断标志
    input  wire RX_interrupt_clear,         //清除接收中断标志
    
    input  wire RX                          //串口RX线
    ); 
    
    localparam  Baud_rate_division_factor = clk_frq/Baud_rate; //分频系数
    localparam  Baud_rate_division_factor_2 = clk_frq/Baud_rate/2;   //采样时间点
    
    localparam  RX_complete = 3;//连续多少个bit周期接收不到起始位 本次接收数据完毕
    
    reg  [3:0] sig_rx;
    
    always @ (posedge clk ) //因为是异步提取信号，通过多级寄存器，防止出现亚稳态,具体原理见 https://www.cnblogs.com/linjie-swust/archive/2012/01/07/YWT.html
    begin //初始化sig_rx
        if(~rst) sig_rx <= 4'b1111;
        else sig_rx <= {sig_rx[2:0],RX};
    end
    
    reg [6:0] sig_maoci;
    
    always @ (posedge clk) //去除亚稳态之后的毛刺信号，取连续七次信号采样，当高电平个数>=4,则为高电平，否则为低电平
    begin
        if(~rst) sig_maoci <= 7'b1111111;
        else sig_maoci <= {sig_maoci[5:0],sig_rx[3]};
    end
    
    wire [2:0] sig_maoci_sum;
    assign sig_maoci_sum = sig_maoci[0] + sig_maoci[1] + sig_maoci[2] +sig_maoci[3]+sig_maoci[4]+sig_maoci[5]+sig_maoci[6];
    
    wire RX_signal;
    
    //assign RX_signal = sig_rx[3]; //只处理亚稳态
    assign RX_signal = (sig_maoci_sum >= 4)? 1'b1:1'b0;
    
    reg [15:0] counter; //分频计数器
    reg [5:0]  RX_data_bytes_counter;//接收数据字节数计数
    reg [3:0]  RX_data_bits_counter;//接收数据位bit数计数 
    reg [3:0]  RX_stop_bits_counter;//接收停止位bit数计数 
    reg        RX_busy;//接收进程忙
	 reg        RX_interrupt_;//接收中断提前标志
    
    
     reg [2:0] RX_state;
    localparam                     RX_IDLE               = 0, //接收空闲状态
                                   RX_START_BIT_DETECTED = 1, //检测到起始位
                                   RX_START_BIT          = 2, //接收抽样起始位
                                   RX_DATA_BITS          = 3,  //接收抽样数据位
                                   RX_PARITY_BIT         = 4,  //接收抽样校验位
                                   RX_STOP_BIT           = 5; //接收抽样停止位
 
                                   

    
    reg [7:0] RX_once_data;
    reg       RX_once_parity_bit;
    wire check_bit; //每一次接收字节的校验位
    assign check_bit = RX_once_data[0] + RX_once_data[1] + RX_once_data[2] + RX_once_data[3] + RX_once_data[4] + RX_once_data[5] + RX_once_data[6] + RX_once_data[7];

    always @ (posedge clk ) //接收状态改变进程
    begin
        if(~rst)
        begin
            counter <= 0;
            RX_data_bytes_counter <= 0;
            RX_data_bits_counter  <= 0;
            RX_stop_bits_counter  <= 0;
            RX_state <= RX_IDLE;
            RX_busy <= 0;
            
            receive_data <= 0;
				receive_data_ <= 0;
            receive_data_bytes <= 0;
            receive_data_check <= 0;
				receive_data_check_all <= 1;
            RX_interrupt <= 0;
				RX_interrupt_ <=0;
        end
        else  if(RX_busy)//正在进行接收，程序接收过程为忙碌
        begin
            if(counter == Baud_rate_division_factor - 1)
                counter <= 0;
            else
                counter <= counter + 1;
                
            if(counter == Baud_rate_division_factor_2-1)//转化检测样本状态，再中间转化抽样状态
            begin
                if(RX_state == RX_START_BIT_DETECTED) //起始位抽样
                    RX_state <= RX_START_BIT;
                else if(RX_state == RX_START_BIT)//上一状态为抽样起始位 
                begin
                    RX_data_bits_counter <= 0;//接收第一个bit
                    RX_data_bytes_counter <= RX_data_bytes_counter+1;//接收字节数+1
                    RX_state <= RX_DATA_BITS;
                end
                else if(RX_state == RX_DATA_BITS)//上一状态为抽样数据位
                begin
                    if(RX_data_bits_counter == data_bits - 1) //已经抽样完这一个字节的数据
                    begin
                        RX_data_bits_counter <= 0;
                        if( parity == 2'b01 || parity == 2'b10 ) //有奇偶校验位,抽样奇偶校验位
                            RX_state <= RX_PARITY_BIT;
                        else
                        begin
                            RX_state <= RX_STOP_BIT;
                            RX_stop_bits_counter  <= 0;
                        end
                    end
                    else
                    begin
                        RX_data_bits_counter <= RX_data_bits_counter + 1;//抽样下一个bit
                        RX_state <= RX_DATA_BITS;
                    end
                end
                else if(RX_state == RX_PARITY_BIT)//上一状态为接收抽样校验位
                begin
                    RX_state <= RX_STOP_BIT;
                    RX_stop_bits_counter  <= 0;
                end
                else if(RX_state == RX_STOP_BIT)
                begin
                   RX_stop_bits_counter <= RX_stop_bits_counter + 1;
                   if(RX_stop_bits_counter == RX_complete)//连续RX_complete次没有再次检测到起始位，本次传输结束
                   begin
                        RX_busy <= 1'b0; //接收状态改为空闲
                        RX_state <= RX_IDLE; //接收链路位空闲
								receive_data_ <= receive_data << (data_depth - receive_data_bytes)*8;//将数据放到最高位////////////////*******************
                        RX_interrupt_ <= 1'b1;//接收完成一次数据
                   end
                end
            end
            else  if(counter == Baud_rate_division_factor_2)//抽样 并且再停止位更新数据寄存器和接收的数据是否满足奇偶校验寄存器
            begin
                if(RX_state == RX_DATA_BITS) //抽样数据
                begin
                    RX_once_data[RX_data_bits_counter] <= RX_signal; //
                end
                else if(RX_state == RX_PARITY_BIT)//抽样奇偶校验
                begin
                    RX_once_parity_bit <= RX_signal;
                end
                else if(RX_state == RX_STOP_BIT && RX_stop_bits_counter == 0)//第一次抽样停止位。更新数据寄存器 将原本的数据寄存器左移八位并加入新的数据；将原本的数检查寄存器左移一位，并加入新的数据检查位
                begin
                    receive_data <= {receive_data[data_depth*8-9 : 0],RX_once_data[7:0]};  //将原本的数据寄存器左移八位并加入新的数据
                    receive_data_bytes <= RX_data_bytes_counter;
                    if(parity == 2'b00 || (parity == 2'b01 && RX_once_parity_bit == check_bit) || (parity == 2'b10 && RX_once_parity_bit == ~check_bit) )  //无校验或校验正确
						  begin
                        receive_data_check <= {receive_data_check[data_depth-2 : 0],1'b1};
								receive_data_check_all <= receive_data_check_all && 1'b1;
						  end
                    else                                                                                                                                  //校验错误
						  begin
                        receive_data_check <= {receive_data_check[data_depth-2 : 0],1'b0};
								receive_data_check_all <= receive_data_check_all && 1'b0;
						  end
                end
            end
            
            if(RX_state == RX_STOP_BIT) //当接收抽样停止位后又出现起始位，说明本次数据传输未完成
            begin
                if(RX_signal == 1'b0)
                begin
                    counter <= 0;
                    RX_state <= RX_START_BIT_DETECTED;
                end
            end
        end
        else  //发送模块处于空闲状态，等待发送脉冲
        begin
            if(RX_state == RX_IDLE && RX_signal == 1'b0) //当接收链路处于空闲状态，且检测到下降沿，开始一次接收
            begin
                RX_busy <= 1'b1; //接收状态改为忙碌
                RX_data_bytes_counter <= 0;
                RX_data_bits_counter  <= 0;
                receive_data <= 0;//接收缓冲区全部置0
					 receive_data_ <= 0;
                receive_data_bytes <= 0;
                receive_data_check <= 0;
					 receive_data_check_all <= 1;
                
                RX_once_data <= 0; //临时接收8位数据缓冲区
                RX_once_parity_bit <= 0;  //临时接收校验位
                
                counter <= 0;
                RX_state <= RX_START_BIT_DETECTED;
                
                RX_interrupt <= 0;
					 RX_interrupt_ <= 0;
            end
            else
            begin
					 if(RX_interrupt_ == 1)
					 begin
						RX_interrupt <= 1;
						RX_interrupt_ <= 0;
					 end
					 else
					 begin
						 if(RX_interrupt_clear == 1) //清除接收中断标志
							  RX_interrupt <= 0;
						 else 
							  RX_interrupt <= RX_interrupt;
					 end
            end
        end
    end
    
endmodule
