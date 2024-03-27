module rst
#(
    parameter delay_cnt = 10 //wait rffe device power on
)
(
    input clk,
    output reg rst_n=0
);

reg [31:0] clk_cnt=0;

always @(posedge clk) 
begin
    if(clk_cnt<=delay_cnt-1)
    begin
        rst_n<=0;
        clk_cnt<=clk_cnt+1;
    end
    else
    begin
        rst_n<=1;
    end
end

endmodule