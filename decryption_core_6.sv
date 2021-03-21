`default_nettype none
module decryption_core_6(
    input logic clk, outer_finish,
    output logic finish, not_found,
    output logic [23:0] new_secret_6
);

wire start_machine, secret_enable;
wire [7:0] secret_key [2:0];
wire reset_n, wren, wren_1, wren_2, wren_3, start_decrypting;
wire [7:0] address, data,address_1,address_2, address_3, data_1, data_2, data_3, rom_q, q;
wire [7:0] decrypted_output;
wire [4:0] rom_address,  result_ram_address;
wire result_ram_wren;



assign secret_key[0] = new_secret_6[23:16];
assign secret_key[1] = new_secret_6[15:8];
assign secret_key[2] = new_secret_6[7:0];

/////// Handling which address line and data line is accessing memory at a time //////////////////////
assign not_found = (new_secret_6 == 24'd4194304);
assign address = start_decrypting ? address_3 : (start_machine ? address_2 : address_1);
assign data = start_decrypting ? data_3 : (start_machine ? data_2 : data_1);
assign wren = start_decrypting ? wren_3 : (start_machine ? wren_2 : wren_1);


//////////////////// Secret Key Counter ///////////////////////////
counter #(24, 24'd3495250) increment_secret_6(
        .clk(clk),
        .reset(1'b0),
        .count_enable(secret_enable),
        .q(new_secret_6)
);

//// State machine that initializes the S memory /////////////////////
init_s_memory_state_machine
to_main_s_6(
    .clk(clk),
    .reset(reset_n),
    .address(address_1),
    .data(data_1),
    .wren(wren_1),
    .done(start_machine)
);

///// State machine that swaps the S memory //////////////////////
swapping_state_machine
change_memory_6(
    .clk(clk),
    .not_found(not_found),
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
visual_message_6(
    .clk(clk),
    .outer_finish(outer_finish),
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
    .finish(finish)
);

///// S memory instantiation //////////////
s_memory
main_s_6 (
    .address(address),
    .clock(clk),
    .data(data),
    .wren(wren),
    .q(q)
);

////// Message Rom instantiation //////////
message_rom
secret_message_6 (
    .address(rom_address),
    .clock(clk),
    .q(rom_q)
);

/////// Result Ram instantiation ///////////
result_ram
decr_y_6(
    .address(result_ram_address),
    .clock(clk),
    .data(decrypted_output),
    .wren(result_ram_wren),
    .q()
);

endmodule