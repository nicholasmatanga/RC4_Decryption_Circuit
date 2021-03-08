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
        HEX5,
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

logic clk, start_machine, enable;
logic [7:0] secret_key [2:0];
wire reset_n, wren, wren_1, wren_2;
wire [7:0] address, data,address_1,address_2, data_1, data_2, q;

assign clk = CLOCK_50;
assign secret_key[0] = 8'b0;
assign secret_key[1] = {6'b0, SW[9:8]};
assign secret_key[2] = SW[7:0];
assign enable = (!KEY[0]);
assign reset_n = (!KEY[3]);
assign address = start_machine ? address_2 : address_1;
assign data = start_machine ? data_2 : data_1;
assign wren = start_machine ? wren_2 : wren_1;

////// Register for start bit //////////
always@(posedge clk or posedge reset_n)
begin
    if(reset_n)
    start_machine <= 1'b0;
    else if(enable) 
    start_machine <= 1'b1;
end

//// State machine that initializes the S memory /////////////////////
init_s_memory_state_machine
to_main_s(
    .clk(clk),
    .address(address_1),
    .data(data_1),
    .wren(wren_1)
);

///// State machine that swaps the S memory //////////////////////
swapping_state_machine
change_memory(
    .clk(clk),
    .start_machine(start_machine),
    .reset(reset_n),
    .from_memory(q),
    .secret_key(secret_key),
    .address(address_2),
    .data(data_2),
    .wren(wren_2)
);

///// S memory instantiation //////////////
s_memory
main_s (
    .address(address),
    .clock(clk),
    .data(data),
    .wren(wren),
    .q(q)
);

endmodule