`timescale 1ns / 1ps
// top module //
module TRAFFIC (
	clk, 	rst, 
	Road1_G, Road1_Y, Road1_R, 
	Road2_G, Road2_Y, Road2_R, 
	Walk_G, Walk_R);

input clk, rst;

output Road1_G, Road1_Y, Road1_R;
output Road2_G, Road2_Y, Road2_R;
output Walk_G, Walk_R;

wire [6:0] cnt;

CNT c1  ( .clk(clk), .rst(rst), .cnt(cnt)
    );

LD  d1  ( .cnt(cnt),
        .Road1_G(Road1_G), .Road1_Y(Road1_Y), .Road1_R(Road1_R),
        .Road2_G(Road2_G), .Road2_Y(Road2_Y), .Road2_R(Road2_R),
        .Walk_G(Walk_G), .Walk_R(Walk_R)
    );


endmodule


// counter //
module CNT(clk, rst, cnt);
input clk;
input rst;
output [6:0]cnt;

reg [6:0]cnt;
reg [6:0]ncnt;

always@(posedge clk or posedge rst) begin
    if (rst)    cnt <= 0;
    else        cnt <= ncnt;

end

always@(*) begin
    if ( &cnt )  ncnt = 7'd0;
    else         ncnt = cnt + 7'd1;
end

endmodule


// light decoder //
module LD(
    cnt,
    Road1_G, Road1_Y, Road1_R,
    Road2_G, Road2_Y, Road2_R,
    Walk_G, Walk_R
    );

input [6:0] cnt;
output Road1_G, Road1_Y, Road1_R;
output Road2_G, Road2_Y, Road2_R;
output Walk_G, Walk_R;

reg [7:0]lights;

always@(*) begin
    if (cnt < 2) lights = 8'b001_001_01;
    else if (/*cnt >= 2 &&*/ cnt < 42) lights = 8'b100_001_01;
    else if (/*cnt >= 42 &&*/ cnt < 47) lights = 8'b010_001_01;
    else if (/*cnt >=47 &&*/ cnt <49) lights = 8'b001_001_01;
    else if (/*cnt >=49 &&*/ cnt <89) lights = 8'b001_100_01;
    else if (/*cnt >=89 &&*/ cnt <94) lights = 8'b001_010_01;
    else if (/*cnt >=94 &&*/ cnt <96) lights = 8'b001_001_01;
    else if (/*cnt >=96 &&*/ cnt <121) lights = 8'b001_001_10;
    else /*if (cnt >=121 && cnt <=127)*/ lights = {6'b001_001, cnt[0], 1'b0};
    // else lights = 8'b001_001_01;
end

assign { Road1_G, Road1_Y, Road1_R, 
        Road2_G, Road2_Y, Road2_R, 
        Walk_G, Walk_R
        } = lights;
        
endmodule