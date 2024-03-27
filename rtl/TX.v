`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: SEU_MMW
// Engineer: XXQ
// 
// Create Date:    14:26:10 07/20/2020 
// Design Name: 
// Module Name:    UART_TX 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 串发送程序，支持多种速率的串口以及支持各种数据格式，停止位格式，支持奇偶校验。
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module UART_TX #(
parameter  Baud_rate = 115200, //默认波特率=115200  支持 4800 9600 19200 57600 115200 230400 460800 921600 
parameter  clk_frq = 100000000,  //默认时钟频率100MHz 请大于100MHz 并且小于250MHz
parameter  data_depth = 36  //默认数据深度为36，单次支持最大data_depth的接收和发送 建议最大不超过63，如果超过63，请改变下面的 send_data_bytes和receive_data_bytes
) 
(
    input  wire clk,             //总体时钟 与clk_frq相匹配
    input  wire rst,             //复位，低电平复位
    
    input  wire [3:0] data_bits, //数据bit 支持5 6 7 8
    input  wire [1:0] stop_bits, //停止位，00=1位停止位，01=1.5位停止位，10=2位停止位
    input  wire [1:0] parity,    //校验位，00=无校验位， 01=偶校，10=奇校验
    
    input  wire [data_depth*8-1:0] send_data, //将要发送的数据  00_00_……00_XX_XX_XX   (XX 为即将发送的数据，从高位发送)
    input  wire [5:0] send_data_bytes,        //将要发送的数据的字节数，36对应6位二进制数  
   
    output wire  TX_ready,                   //可以进行发送的标志 高电平表示TX模块可以使用。可以进行发送
    input  wire start_TX,                   //进行一次发送进程，高电平脉冲信号，高电平持续时间不小于clk的两个时钟周期
    
    output reg  TX                         //串口TX线
    ); 
    
    localparam  Baud_rate_division_factor = clk_frq/Baud_rate;//一个字符对应多少个始终周期
    localparam  Baud_rate_division_factor_2 = clk_frq/Baud_rate/2;//在中间位置采样最精准
    
    reg [15:0] counter; //分频计数器，100M/10k=1w，够用
    reg [5:0]  send_data_bytes_counter;//发送数据字节数计数
    reg [3:0]  send_data_bits_counter;//发送数据位bit数计数 
    reg [3:0]  send_stop_bits_counter;//发送停止位bit数计数 
    reg        TX_busy = 0;//发送进程忙
    
    assign TX_ready = ~TX_busy;
    
    reg [2:0] send_state;
    localparam                     SEND_IDLE       = 0, //发送空闲状态
                                   SEND_START_BIT  = 1, //发送送起始位
                                   SEND_DATA_BITS  = 2,  //发送数据位
                                   SEND_PARITY_BIT = 3,  //发送校验位
                                   SEND_STOP_BIT   = 4; //发送停止位
 
                                   

    always @ (posedge clk) //发送状态改变进程
    begin
        if(~rst) //低电平复位
        begin
            counter <= 0;
            send_data_bytes_counter <= 0;
            send_data_bits_counter  <= 0;
            send_stop_bits_counter  <= 0;
            send_state <= SEND_IDLE;
            TX_busy <= 0;
        end
        else  if(TX_busy)//正在进行发送
        begin
            if(counter == Baud_rate_division_factor - 1)
                counter <= 0;
            else
                counter <= counter + 1;
                
            if(counter == 1)//转化发送
            begin
                if(send_state == SEND_IDLE) //起始发送
                    send_state <= SEND_START_BIT;
                else if(send_state == SEND_START_BIT)//上一状态为发送起始位 
                begin
                    send_data_bits_counter <= 0;//发送第一个bit
                    send_state <= SEND_DATA_BITS;
                end
                else if(send_state == SEND_DATA_BITS)//上一状态为发送数据
                begin
                    if(send_data_bits_counter == data_bits - 1) //已经发送完这一个字节的数据
                    begin
                        send_data_bits_counter <= 0;
                        if( parity == 2'b01 || parity == 2'b10 ) //有奇偶校验位
                            send_state <= SEND_PARITY_BIT;
                        else
                        begin
                            send_state <= SEND_STOP_BIT;
                            send_stop_bits_counter  <= 0;
                        end
                    end
                    else
                    begin
                        send_data_bits_counter <= send_data_bits_counter + 1;//发送下一个bit
                        send_state <= SEND_DATA_BITS;
                    end
                end
                else if(send_state == SEND_PARITY_BIT)//上一状态为发送校验位
                begin
                    send_state <= SEND_STOP_BIT;
                    send_stop_bits_counter  <= 0;
                end
                else if(send_state == SEND_STOP_BIT)
                begin
                    if(stop_bits == 2'b00)// 1位停止位
                    begin
                        if(send_data_bytes_counter == send_data_bytes - 1)//已经发送完成所有数据
                        begin
                            send_data_bytes_counter <= 0;
                            send_state <= SEND_IDLE;
                            TX_busy <= 1'b0; //TX 空闲
                        end
                        else
                        begin
                            send_data_bytes_counter <= send_data_bytes_counter + 1;
                            send_state <= SEND_START_BIT;
                        end
                    end
                    else if(stop_bits == 2'b01)// 1.5位停止位
                    begin
                        send_stop_bits_counter <= send_stop_bits_counter + 1;
                    end
                    else if(stop_bits == 2'b10)// 2位停止位
                    begin
                        if(send_stop_bits_counter == 1)//第二次停止位
                        begin
                            if(send_data_bytes_counter == send_data_bytes - 1)//已经发送完成所有数据
                            begin
                                send_data_bytes_counter <= 0;
                                send_state <= SEND_IDLE;
                                TX_busy <= 1'b0; //TX 空闲
                            end
                            else
                            begin
                                send_data_bytes_counter <= send_data_bytes_counter + 1;
                                send_state <= SEND_START_BIT;
                            end
                        end
                        else //第一次停止位
                            send_stop_bits_counter <= send_stop_bits_counter + 1;
                    end
                end
            end
            else if (counter == Baud_rate_division_factor_2 && stop_bits == 2'b01 && send_stop_bits_counter == 1) //1.5位停止位,第二个半个停止位，单独操作
            begin
                counter <= 0;
                send_stop_bits_counter <= 0;
                if(send_data_bytes_counter == send_data_bytes - 1)//已经发送完成所有数据
                begin
                    send_data_bytes_counter <= 0;
                    send_state <= SEND_IDLE;
                    TX_busy <= 1'b0; //TX 空闲
                end
                else
                begin
                    send_data_bytes_counter <= send_data_bytes_counter + 1;
                    send_state <= SEND_IDLE;
                end
            end
        end
        else  //发送模块处于空闲状态，等待发送脉冲
        begin
            if(start_TX == 1'b1)//开始一次发送
            begin
                TX_busy <= 1'b1; //发送状态为忙碌
                send_data_bytes_counter <= 0;
                send_data_bits_counter  <= 0;
                counter <= 0;
                send_state <= SEND_IDLE;
            end
        end
    end
    
    wire [9:0] send_start_once_addr;
    assign send_start_once_addr = {send_data_bytes - send_data_bytes_counter - 1,3'b000};//最高字节先发送
    
    reg check_bit;
    
    always @(*) //根据不同位数，计算校验
    begin
      case(data_bits)
      4'h5:check_bit = send_data[send_start_once_addr] + send_data[send_start_once_addr + 1] + send_data[send_start_once_addr + 2] +send_data[send_start_once_addr + 3]
    + send_data[send_start_once_addr + 4] ;
      4'h6:check_bit = send_data[send_start_once_addr] + send_data[send_start_once_addr + 1] + send_data[send_start_once_addr + 2] +send_data[send_start_once_addr + 3]
    + send_data[send_start_once_addr + 4] + send_data[send_start_once_addr + 5] ;
      4'h7:check_bit = send_data[send_start_once_addr] + send_data[send_start_once_addr + 1] + send_data[send_start_once_addr + 2] +send_data[send_start_once_addr + 3]
    + send_data[send_start_once_addr + 4] + send_data[send_start_once_addr + 5] +send_data[send_start_once_addr + 6];
      4'h8:check_bit = send_data[send_start_once_addr] + send_data[send_start_once_addr + 1] + send_data[send_start_once_addr + 2] +send_data[send_start_once_addr + 3]
    + send_data[send_start_once_addr + 4] + send_data[send_start_once_addr + 5] +send_data[send_start_once_addr + 6] +send_data[send_start_once_addr + 7];
      default: check_bit = send_data[send_start_once_addr] + send_data[send_start_once_addr + 1] + send_data[send_start_once_addr + 2] +send_data[send_start_once_addr + 3]
    + send_data[send_start_once_addr + 4] + send_data[send_start_once_addr + 5] +send_data[send_start_once_addr + 6] +send_data[send_start_once_addr + 7];
      endcase
    end
    
    always @ (*)  //发射状态
    begin
        if(~rst)
        begin
            TX = 1;
        end
        else 
        case(send_state)
            SEND_IDLE: begin                 //发射链路空闲
                TX = 1;
            end
            SEND_START_BIT: begin            //起始位
                TX = 0;  
            end
            SEND_DATA_BITS: begin           //数据位
                TX = send_data[send_start_once_addr + send_data_bits_counter];
            end
            SEND_PARITY_BIT:begin           //奇偶校验位
                if(parity == 2'b01)  //偶校验
                    TX = check_bit;
                else                //奇校验
                    TX = ~check_bit;
            end
            SEND_STOP_BIT: begin            //停止位
                TX = 1;  
            end
            default: begin
                TX = 1;
            end
        endcase
    end



endmodule
