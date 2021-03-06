`default_nettype none
module swapping_state_machine (
    input logic clk, start_machine,reset, not_found,
    input logic [7:0] from_s_memory,
    input logic [7:0] secret_key [2:0],
    output logic [7:0] address, data,
    output logic wren, finish
);

logic count_enable, done;
logic [7:0] j_index;
logic [7:0] i_index;
logic [7:0] modded_index;
logic [7:0] from_counter;
logic [7:0] modded_secret_key_value;
logic [7:0] sum_result;
logic [7:0] si_value;
logic [7:0] sj_value;
logic [10:0] state, next_state;


//////// State Encodings /////////////
parameter [10:0] WAIT = 11'b00000_000000,
                MOD_INDEX = 11'b00001_000000,
                MOD_SECRET = 11'b00010_000000,
                SUM_NUMBERS = 11'b00011_000000,
                FETCH_SI = 11'b00100_000000,
                SWAP_TO_SJ_ADDRESS = 11'b00101_000100,
                FETCH_AND_TEMP_SJ = 11'b00110_000100,
                WRITE_SI_TO_SJ = 11'b00111_000101,
                WAIT_TO_SJ = 11'b01000_000101,
                SWAP_TO_SI_ADDRESS = 11'b01001_000000,
                WRITE_SJ_TO_SI = 11'b01010_000001,
                WAIT_TO_SI = 11'b01011_000001,
                IS_SWAP_DONE = 11'b01100_000000,
                FINISH = 11'b01101_001000,
                BUFFER_STATE = 11'b01110_000000,
                INCREMENT_INDEX = 11'b01111_000010;

initial state = WAIT;

parameter [2:0] keylength = 3'b011;

/////// i_index counter //////////////
counter swap_counter(
            .clk(clk),
            .reset(reset),
            .count_enable(count_enable),
            .q(from_counter)
);

//// State Register //////
always_ff@(posedge clk or posedge reset)
begin
    if(reset) state <= WAIT;
    else state <= next_state;
end

////// i index register ///////
always_ff@(posedge clk or posedge reset)
begin
    if(reset) i_index <= 0;
    else i_index <= from_counter;
end

////// j index register ////////
always_ff@(posedge clk or posedge reset)
begin
    if(reset) j_index <= 0;
    else j_index <= sum_result;
end

/////// Next State Logic ////////////
always_comb
begin
    case(state)
    WAIT:   if(start_machine && !not_found) next_state = MOD_INDEX;
            else next_state = WAIT;
    MOD_INDEX: next_state = MOD_SECRET;
    MOD_SECRET: next_state = SUM_NUMBERS;
    SUM_NUMBERS: next_state = FETCH_SI;
    FETCH_SI: next_state = SWAP_TO_SJ_ADDRESS;
    SWAP_TO_SJ_ADDRESS: next_state = FETCH_AND_TEMP_SJ;
    FETCH_AND_TEMP_SJ: next_state = WRITE_SI_TO_SJ;
    WRITE_SI_TO_SJ: next_state = WAIT_TO_SJ;
    WAIT_TO_SJ: next_state = SWAP_TO_SI_ADDRESS;
    SWAP_TO_SI_ADDRESS: next_state = WRITE_SJ_TO_SI;
    WRITE_SJ_TO_SI: next_state = WAIT_TO_SI;
    WAIT_TO_SI: next_state = IS_SWAP_DONE;
    IS_SWAP_DONE:   if(done) next_state = FINISH;
                    else next_state = INCREMENT_INDEX;
    INCREMENT_INDEX: next_state = BUFFER_STATE;
    BUFFER_STATE: next_state = MOD_INDEX;
    FINISH: next_state = FINISH;
    default: next_state = WAIT;
    endcase
end

//////////// Output for what happens when in a particular state /////////////////
always@(posedge clk)
begin
    if(reset)
        begin
            modded_index <= 0;
            modded_secret_key_value <= 0;
            sum_result <= 0;
            si_value <= 0;
            sj_value <= 0;
            data <= 0;
        end 
    case(state)
    MOD_INDEX: modded_index <= i_index % keylength;
    MOD_SECRET: modded_secret_key_value <= secret_key[modded_index];
    SUM_NUMBERS: sum_result <= j_index + from_s_memory + modded_secret_key_value;
    FETCH_SI: si_value <= from_s_memory;
    FETCH_AND_TEMP_SJ:  sj_value <= from_s_memory;
    WRITE_SI_TO_SJ: data <= si_value;
    WRITE_SJ_TO_SI: data <= sj_value;
    endcase
end
 
////// Output Logic ///////
assign wren = state[0];
assign count_enable = state[1];
assign address = state[2] ? j_index : i_index;
assign finish = state[3];
assign done = (i_index == 8'hFF);

endmodule