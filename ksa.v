`default_nettype none
module ksa (
        CLOCK_50,
        KEY,
        SW,
        LEDR,
        HEX0,
        HEX1,
        HEX2,
        HEX3,
        HEX4,
        HEX5
);
/////////////// CLOCK ////////////////////
input CLOCK_50;

////////////// LED //////////////////////
output [9:0] LEDR;

////////////// KEY ////////////////////
input [3:0] KEY;

////////////// SW //////////////////////
input [9:0] SW;

///////////// SEG7 /////////////////////
output [6:0] HEX0;
output [6:0] HEX1;
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX4;
output [6:0] HEX5;

wire clk;
wire outer_finish, not_found;
wire finish_1, finish_2, finish_3, finish_4, finish_5, finish_6;
wire [23:0] new_secret, new_secret_1, new_secret_2, new_secret_3, new_secret_4, new_secret_5, new_secret_6;

assign outer_finish = finish_1 | finish_2 | finish_3 | finish_4 | finish_5 | finish_6;
assign LEDR[0] = outer_finish;
assign LEDR[1] = not_found;
assign clk = CLOCK_50;

////////// Code which chooses which secret key to display if there is a final result ///////////////////
always@(*)
begin
    if(outer_finish)
    begin
        if(finish_1)
            new_secret = new_secret_1;
        else if(finish_2)
            new_secret = new_secret_2;
        else if(finish_3)
            new_secret = new_secret_3;
        else if(finish_4)
            new_secret = new_secret_4;
        else if(finish_5)
            new_secret = new_secret_5;
        else 
            new_secret = new_secret_6;
    end
    else 
        new_secret = new_secret_1;
end


/////////////// Decryption Core Instantiations ////////////////////////
decryption_core_1
core_1(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_1),
    .new_secret_1(new_secret_1)
);

decryption_core_2
core_2(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_2),
    .new_secret_2(new_secret_2)
);

decryption_core_3
core_3(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_3),
    .new_secret_3(new_secret_3)
);

decryption_core_4
core_4(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_4),
    .new_secret_4(new_secret_4)
);

decryption_core_5
core_5(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_5),
    .new_secret_5(new_secret_5)
);

decryption_core_6
core_6(
    .clk(clk),
    .outer_finish(outer_finish),
    .finish(finish_6),
    .new_secret_6(new_secret_6),
    .not_found(not_found)
);




/////// Seven Segment Display /////////////
SevenSegmentDisplayDecoder inst_0( .ssOut(HEX0), .nIn(new_secret[3:0]));
SevenSegmentDisplayDecoder inst_1( .ssOut(HEX1), .nIn(new_secret[7:4]));
SevenSegmentDisplayDecoder inst_2( .ssOut(HEX2), .nIn(new_secret[11:8]));
SevenSegmentDisplayDecoder inst_3( .ssOut(HEX3), .nIn(new_secret[15:12]));
SevenSegmentDisplayDecoder inst_4( .ssOut(HEX4), .nIn(new_secret[19:16]));
SevenSegmentDisplayDecoder inst_5( .ssOut(HEX5), .nIn(new_secret[23:20]));

endmodule