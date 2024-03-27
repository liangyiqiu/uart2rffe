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
// Description: �����ͳ���֧�ֶ������ʵĴ����Լ�֧�ָ������ݸ�ʽ��ֹͣλ��ʽ��֧����żУ�顣
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
parameter  Baud_rate = 115200, //Ĭ�ϲ�����=115200  ֧�� 4800 9600 19200 57600 115200 230400 460800 921600 
parameter  clk_frq = 100000000,  //Ĭ��ʱ��Ƶ��100MHz �����100MHz ����С��250MHz
parameter  data_depth = 36  //Ĭ���������Ϊ36������֧�����data_depth�Ľ��պͷ��� ������󲻳���63���������63����ı������ send_data_bytes��receive_data_bytes
) 
(
    input  wire clk,             //����ʱ�� ��clk_frq��ƥ��
    input  wire rst,             //��λ���͵�ƽ��λ
    
    input  wire [3:0] data_bits, //����bit ֧��5 6 7 8
    input  wire [1:0] stop_bits, //ֹͣλ��00=1λֹͣλ��01=1.5λֹͣλ��10=2λֹͣλ
    input  wire [1:0] parity,    //У��λ��00=��У��λ�� 01=żУ��10=��У��
    
    input  wire [data_depth*8-1:0] send_data, //��Ҫ���͵�����  00_00_����00_XX_XX_XX   (XX Ϊ�������͵����ݣ��Ӹ�λ����)
    input  wire [5:0] send_data_bytes,        //��Ҫ���͵����ݵ��ֽ�����36��Ӧ6λ��������  
   
    output wire  TX_ready,                   //���Խ��з��͵ı�־ �ߵ�ƽ��ʾTXģ�����ʹ�á����Խ��з���
    input  wire start_TX,                   //����һ�η��ͽ��̣��ߵ�ƽ�����źţ��ߵ�ƽ����ʱ�䲻С��clk������ʱ������
    
    output reg  TX                         //����TX��
    ); 
    
    localparam  Baud_rate_division_factor = clk_frq/Baud_rate;//һ���ַ���Ӧ���ٸ�ʼ������
    localparam  Baud_rate_division_factor_2 = clk_frq/Baud_rate/2;//���м�λ�ò����׼
    
    reg [15:0] counter; //��Ƶ��������100M/10k=1w������
    reg [5:0]  send_data_bytes_counter;//���������ֽ�������
    reg [3:0]  send_data_bits_counter;//��������λbit������ 
    reg [3:0]  send_stop_bits_counter;//����ֹͣλbit������ 
    reg        TX_busy = 0;//���ͽ���æ
    
    assign TX_ready = ~TX_busy;
    
    reg [2:0] send_state;
    localparam                     SEND_IDLE       = 0, //���Ϳ���״̬
                                   SEND_START_BIT  = 1, //��������ʼλ
                                   SEND_DATA_BITS  = 2,  //��������λ
                                   SEND_PARITY_BIT = 3,  //����У��λ
                                   SEND_STOP_BIT   = 4; //����ֹͣλ
 
                                   

    always @ (posedge clk) //����״̬�ı����
    begin
        if(~rst) //�͵�ƽ��λ
        begin
            counter <= 0;
            send_data_bytes_counter <= 0;
            send_data_bits_counter  <= 0;
            send_stop_bits_counter  <= 0;
            send_state <= SEND_IDLE;
            TX_busy <= 0;
        end
        else  if(TX_busy)//���ڽ��з���
        begin
            if(counter == Baud_rate_division_factor - 1)
                counter <= 0;
            else
                counter <= counter + 1;
                
            if(counter == 1)//ת������
            begin
                if(send_state == SEND_IDLE) //��ʼ����
                    send_state <= SEND_START_BIT;
                else if(send_state == SEND_START_BIT)//��һ״̬Ϊ������ʼλ 
                begin
                    send_data_bits_counter <= 0;//���͵�һ��bit
                    send_state <= SEND_DATA_BITS;
                end
                else if(send_state == SEND_DATA_BITS)//��һ״̬Ϊ��������
                begin
                    if(send_data_bits_counter == data_bits - 1) //�Ѿ���������һ���ֽڵ�����
                    begin
                        send_data_bits_counter <= 0;
                        if( parity == 2'b01 || parity == 2'b10 ) //����żУ��λ
                            send_state <= SEND_PARITY_BIT;
                        else
                        begin
                            send_state <= SEND_STOP_BIT;
                            send_stop_bits_counter  <= 0;
                        end
                    end
                    else
                    begin
                        send_data_bits_counter <= send_data_bits_counter + 1;//������һ��bit
                        send_state <= SEND_DATA_BITS;
                    end
                end
                else if(send_state == SEND_PARITY_BIT)//��һ״̬Ϊ����У��λ
                begin
                    send_state <= SEND_STOP_BIT;
                    send_stop_bits_counter  <= 0;
                end
                else if(send_state == SEND_STOP_BIT)
                begin
                    if(stop_bits == 2'b00)// 1λֹͣλ
                    begin
                        if(send_data_bytes_counter == send_data_bytes - 1)//�Ѿ����������������
                        begin
                            send_data_bytes_counter <= 0;
                            send_state <= SEND_IDLE;
                            TX_busy <= 1'b0; //TX ����
                        end
                        else
                        begin
                            send_data_bytes_counter <= send_data_bytes_counter + 1;
                            send_state <= SEND_START_BIT;
                        end
                    end
                    else if(stop_bits == 2'b01)// 1.5λֹͣλ
                    begin
                        send_stop_bits_counter <= send_stop_bits_counter + 1;
                    end
                    else if(stop_bits == 2'b10)// 2λֹͣλ
                    begin
                        if(send_stop_bits_counter == 1)//�ڶ���ֹͣλ
                        begin
                            if(send_data_bytes_counter == send_data_bytes - 1)//�Ѿ����������������
                            begin
                                send_data_bytes_counter <= 0;
                                send_state <= SEND_IDLE;
                                TX_busy <= 1'b0; //TX ����
                            end
                            else
                            begin
                                send_data_bytes_counter <= send_data_bytes_counter + 1;
                                send_state <= SEND_START_BIT;
                            end
                        end
                        else //��һ��ֹͣλ
                            send_stop_bits_counter <= send_stop_bits_counter + 1;
                    end
                end
            end
            else if (counter == Baud_rate_division_factor_2 && stop_bits == 2'b01 && send_stop_bits_counter == 1) //1.5λֹͣλ,�ڶ������ֹͣλ����������
            begin
                counter <= 0;
                send_stop_bits_counter <= 0;
                if(send_data_bytes_counter == send_data_bytes - 1)//�Ѿ����������������
                begin
                    send_data_bytes_counter <= 0;
                    send_state <= SEND_IDLE;
                    TX_busy <= 1'b0; //TX ����
                end
                else
                begin
                    send_data_bytes_counter <= send_data_bytes_counter + 1;
                    send_state <= SEND_IDLE;
                end
            end
        end
        else  //����ģ�鴦�ڿ���״̬���ȴ���������
        begin
            if(start_TX == 1'b1)//��ʼһ�η���
            begin
                TX_busy <= 1'b1; //����״̬Ϊæµ
                send_data_bytes_counter <= 0;
                send_data_bits_counter  <= 0;
                counter <= 0;
                send_state <= SEND_IDLE;
            end
        end
    end
    
    wire [9:0] send_start_once_addr;
    assign send_start_once_addr = {send_data_bytes - send_data_bytes_counter - 1,3'b000};//����ֽ��ȷ���
    
    reg check_bit;
    
    always @(*) //���ݲ�ͬλ��������У��
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
    
    always @ (*)  //����״̬
    begin
        if(~rst)
        begin
            TX = 1;
        end
        else 
        case(send_state)
            SEND_IDLE: begin                 //������·����
                TX = 1;
            end
            SEND_START_BIT: begin            //��ʼλ
                TX = 0;  
            end
            SEND_DATA_BITS: begin           //����λ
                TX = send_data[send_start_once_addr + send_data_bits_counter];
            end
            SEND_PARITY_BIT:begin           //��żУ��λ
                if(parity == 2'b01)  //żУ��
                    TX = check_bit;
                else                //��У��
                    TX = ~check_bit;
            end
            SEND_STOP_BIT: begin            //ֹͣλ
                TX = 1;  
            end
            default: begin
                TX = 1;
            end
        endcase
    end



endmodule
