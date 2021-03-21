`default_nettype none
module decryption_state_machine(
            input logic clk, start_machine, outer_finish,
            input logic [7:0] encrypted_input,
            input logic [7:0] from_s_memory,
            output logic [7:0] decrypted_output,
            output logic [7:0] data, address, 
            output logic [4:0] rom_address,
            output logic [4:0] result_ram_address,
            output logic wren, result_ram_wren, reset, secret_enable, finish
);

logic count_enable, done, is_valid;
logic [4:0] k_index;
logic [7:0] i_index;
logic [7:0] j_index;
logic [7:0] f_index;
logic [7:0] modded_address;
logic [7:0] sum_j_result;
logic [7:0] sum_i_result;
logic [7:0] si_value;
logic [7:0] sj_value;
logic [10:0] state, next_state;

////////////// State_Encodings ////////////////////////////
parameter [10:0] WAIT = 11'b00000_000000,
                INCREMENT_I_INDEX = 11'b00001_000000,
                WAIT_FOR_INC_I = 11'b00010_000000,
                WAIT_FOR_READ = 11'b00011_000000,
                SUM_J_INDEX = 11'b00100_000000,
                WAIT_FOR_SUM_J = 11'b00101_000000,
                FETCH_SI = 11'b00110_000000,
                WAIT_FOR_SI_READ = 11'b00111_000000,
                SWAP_TO_SJ_ADDRESS = 11'b01000_000100,
                FETCH_SJ = 11'b01001_000100,
                WRITE_SI_TO_SJ = 11'b01010_000101,
                WAIT_TO_SJ = 11'b01011_000101,
                WAIT_ANOTHER_SJ = 11'b01100_000101,
                SWAP_TO_SI_ADDRESS = 11'b01101_000000,
                WRITE_SJ_TO_SI = 11'b01110_000001,
                WAIT_TO_SI = 11'b01111_000001,
                COMPUTE_MOD_ADDRESS = 11'b10000_000000,
                FETCH_FROM_MOD_ADDRESS = 11'b10001_100000,
                GIVE_TO_F = 11'b10010_100000,
                WAIT_FOR_F = 11'b10011_000000,
                DO_XOR = 11'b10100_000000,
                WRITE_TO_RESULT_RAM = 11'b10101_010000,
                WAIT_FOR_RESULT_RAM = 11'b10110_010000,
                CHECK_IF_DONE = 11'b10111_000000,
                INCREMENT_K_INDEX = 11'b11000_000010,
                FINISHED = 11'b11001_000000,
                BUFFER_STATE = 11'b11010_000000,
                CHECK_VALID = 11'b11011_000000,
                KEY_ENABLE = 11'b11100_000000,
                RESET_ALL = 11'b11110_001000,
                ELSE_FINISH = 11'b11111_000000;


//////// Count for the k_index /////////
counter #(5) decrypt_counter(
        .clk(clk),
        .reset(reset),
        .count_enable(count_enable),
        .q(k_index)
);

//// State Register //////
always_ff@(posedge clk)
begin
    if(reset) state <= WAIT;
    else state <=next_state;
end

////// i index register ///////
always_ff@(posedge clk or posedge reset)
begin
    if(reset) i_index <= 0;
    else i_index <= sum_i_result;
end

////// j index register ////////
always_ff@(posedge clk or posedge reset)
begin
    if(reset) j_index <= 0;
    else j_index <= sum_j_result;
end

//////// Next State Logic /////////////
always_comb
begin
     case(state)
    ///// Main Program ///////
    WAIT:   if(start_machine) next_state = INCREMENT_I_INDEX;
            else next_state = WAIT;
    INCREMENT_I_INDEX: next_state = WAIT_FOR_INC_I;
    WAIT_FOR_INC_I: next_state = WAIT_FOR_READ ;
    WAIT_FOR_READ: next_state = SUM_J_INDEX;
    SUM_J_INDEX: next_state = WAIT_FOR_SUM_J;
    WAIT_FOR_SUM_J: next_state = FETCH_SI;
    FETCH_SI: next_state = WAIT_FOR_SI_READ;
    WAIT_FOR_SI_READ: next_state = SWAP_TO_SJ_ADDRESS;
    SWAP_TO_SJ_ADDRESS: next_state = FETCH_SJ;
    FETCH_SJ: next_state = WRITE_SI_TO_SJ;
    WRITE_SI_TO_SJ: next_state = WAIT_TO_SJ;
    WAIT_TO_SJ: next_state = WAIT_ANOTHER_SJ;
    WAIT_ANOTHER_SJ: next_state = SWAP_TO_SI_ADDRESS;
    SWAP_TO_SI_ADDRESS: next_state = WRITE_SJ_TO_SI;
    WRITE_SJ_TO_SI: next_state = WAIT_TO_SI;
    WAIT_TO_SI: next_state = COMPUTE_MOD_ADDRESS;
    COMPUTE_MOD_ADDRESS: next_state = FETCH_FROM_MOD_ADDRESS;
    FETCH_FROM_MOD_ADDRESS: next_state = GIVE_TO_F;
    GIVE_TO_F: next_state = WAIT_FOR_F;
    WAIT_FOR_F: next_state = DO_XOR;
    DO_XOR: next_state = BUFFER_STATE;

    /////// Data Validity Check ////////
    BUFFER_STATE: next_state = CHECK_VALID;
    CHECK_VALID:    if(is_valid) next_state = WRITE_TO_RESULT_RAM;
                    else next_state = KEY_ENABLE;
    KEY_ENABLE: next_state = RESET_ALL;
    RESET_ALL: next_state = WAIT;

    ///// Back to Main Program /////
    WRITE_TO_RESULT_RAM: next_state = WAIT_FOR_RESULT_RAM;
    WAIT_FOR_RESULT_RAM: next_state = CHECK_IF_DONE;
    CHECK_IF_DONE:  if(done) next_state = FINISHED;
                    else if(outer_finish) next_state = ELSE_FINISH;
                    else next_state = INCREMENT_K_INDEX;
    INCREMENT_K_INDEX: next_state = INCREMENT_I_INDEX;
    FINISHED: next_state = FINISHED;
    ELSE_FINISH: next_state = ELSE_FINISH;
    default: next_state = WAIT;
    endcase
end

//////////// Output for what happens when in a particular state /////////////////
always@(posedge clk)
begin
    if(reset)
        begin
            sum_i_result <= 0;
            sum_j_result <= 0;
            si_value <= 0;
            sj_value <= 0;
            data <= 0;
            modded_address <= 0;
            f_index <= 0;
            decrypted_output <= 0;
        end
    case(state)
    INCREMENT_I_INDEX:  sum_i_result <= i_index + 1'b1;
    SUM_J_INDEX: sum_j_result <= j_index + from_s_memory; 
    FETCH_SI: si_value <= from_s_memory;
    FETCH_SJ: sj_value <= from_s_memory;
    WRITE_SI_TO_SJ: data <= si_value;
    WRITE_SJ_TO_SI: data <= sj_value;
    COMPUTE_MOD_ADDRESS: modded_address <= si_value + sj_value;
    GIVE_TO_F: f_index <= from_s_memory;
    DO_XOR: decrypted_output <= f_index ^ encrypted_input;
    endcase
end

////////// Input logic ///////////////////
assign done = (k_index == 5'b11111);
assign is_valid = ((decrypted_output >= 32'd97)&&(decrypted_output <= 32'd122)) | (decrypted_output == 32'd32);

//////// Output logic /////////
assign wren = state[0];
assign count_enable = state[1];
assign address = state[5] ? modded_address : (state[2] ? j_index : i_index);
assign rom_address = k_index;
assign result_ram_address = k_index;
assign result_ram_wren = state[4];
assign finish = (state == FINISHED);
assign reset = state[3];
assign secret_enable = (state == KEY_ENABLE);

endmodule