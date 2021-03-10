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

logic clk, start_machine;
logic [7:0] secret_key [2:0];
wire reset_n, wren, wren_1, wren_2, wren_3, start_decrypting;
wire [7:0] address, data,address_1,address_2, address_3, data_1, data_2, data_3, rom_q, q;
wire [7:0] decrypted_output;
wire [4:0] rom_address,  result_ram_address;
wire result_ram_wren;

assign clk = CLOCK_50;
assign secret_key[0] = 8'b0;
assign secret_key[1] = {6'b0, SW[9:8]};
assign secret_key[2] = SW[7:0];
assign reset_n = (!KEY[3]);



assign address = start_decrypting ? address_3 : (start_machine ? address_2 : address_1);
assign data = start_decrypting ? data_3 : (start_machine ? data_2 : data_1);
assign wren = start_decrypting ? wren_3 : (start_machine ? wren_2 : wren_1);

//// State machine that initializes the S memory /////////////////////
init_s_memory_state_machine
to_main_s(
    .clk(clk),
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
    .result_ram_wren(result_ram_wren)
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

endmodule