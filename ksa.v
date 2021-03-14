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

wire [23:0] new_secret;
wire clk, start_machine, secret_enable;
wire [7:0] secret_key [2:0];
wire reset_n, wren, wren_1, wren_2, wren_3, start_decrypting;
wire [7:0] address, data,address_1,address_2, address_3, data_1, data_2, data_3, rom_q, q;
wire [7:0] decrypted_output;
wire [4:0] rom_address,  result_ram_address;
wire result_ram_wren;

assign clk = CLOCK_50;
assign secret_key[0] = new_secret[23:16];
assign secret_key[1] = new_secret[15:8];
assign secret_key[2] = new_secret[7:0];

// assign secret_key[0] = 8'b0;
// assign secret_key[1] = {6'b0, SW[9:8]};
// assign secret_key[2] = SW[7:0];


assign address = start_decrypting ? address_3 : (start_machine ? address_2 : address_1);
assign data = start_decrypting ? data_3 : (start_machine ? data_2 : data_1);
assign wren = start_decrypting ? wren_3 : (start_machine ? wren_2 : wren_1);


//////////////////// Secret Key Counter ///////////////////////////
counter #(24) increment_secret(
        .clk(clk),
        .reset(1'b0),
        .count_enable(secret_enable),
        .q(new_secret)
);

//// State machine that initializes the S memory /////////////////////
init_s_memory_state_machine
to_main_s(
    .clk(clk),
    .reset(reset_n),
    .address(address_1),
    .data(data_1),
    .wren(wren_1),
    .done(start_machine)
);

///// State machine that swaps the S memory //////////////////////
swapping_state_machine
change_memory(
    .clk(clk),
    .start_machine(start_machine),
    .reset(reset_n),
    .from_s_memory(q),
    .secret_key(secret_key),
    .address(address_2),
    .data(data_2),
    .wren(wren_2),
    .finish(start_decrypting)
);

//////// State machine that decrypts the message //////////////////
decryption_state_machine
visual_message(
    .clk(clk),
    .start_machine(start_decrypting),
    .reset(reset_n),
    .encrypted_input(rom_q),
    .from_s_memory(q),
    .decrypted_output(decrypted_output),
    .data(data_3),
    .address(address_3),
    .rom_address(rom_address),
    .result_ram_address(result_ram_address),
    .wren(wren_3),
    .result_ram_wren(result_ram_wren),
    .secret_enable(secret_enable),
    .finish(LEDR[0])
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

////// Message Rom instantiation //////////
message_rom
secret_message (
    .address(rom_address),
    .clock(clk),
    .q(rom_q)
);

/////// Result Ram instantiation ///////////
result_ram
decr_y(
    .address(result_ram_address),
    .clock(clk),
    .data(decrypted_output),
    .wren(result_ram_wren),
    .q()
);

/////// Seven Segment Display /////////////
SevenSegmentDisplayDecoder inst_0( .ssOut(HEX0), .nIn(new_secret[3:0]));
SevenSegmentDisplayDecoder inst_1( .ssOut(HEX1), .nIn(new_secret[7:4]));
SevenSegmentDisplayDecoder inst_2( .ssOut(HEX2), .nIn(new_secret[11:8]));
SevenSegmentDisplayDecoder inst_3( .ssOut(HEX3), .nIn(new_secret[15:12]));
SevenSegmentDisplayDecoder inst_4( .ssOut(HEX4), .nIn(new_secret[19:16]));
SevenSegmentDisplayDecoder inst_5( .ssOut(HEX5), .nIn(new_secret[23:20]));

endmodule