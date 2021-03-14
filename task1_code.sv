`default_nettype none
module init_s_memory_state_machine(
        input logic clk,reset,
        output logic [7:0] address, data,
        output logic wren, done
);

logic count_enable, finish;
logic [7:0] counter_value;
logic [4:0] state, next_state;

//////////// State encodings ///////////////
parameter [4:0] IDLE = 5'b100_00,
                INIT_STATE = 5'b011_00,
                WRITE_TO_MEM = 5'b000_01,
                INCREMENT_COUNT = 5'b000_10,
                CHECK_IF_DONE = 5'b001_00,
                BUFFER_STATE = 5'b010_00;

///// Specifying starting state of the state machine /////////
initial state = INIT_STATE;

////// Counter instantiation which increments values sent to memory ////////////
counter send_to_s(
    .clk(clk),
    .reset(reset),
    .count_enable(count_enable),
    .q(counter_value)
);

/////// State register //////////////////
always_ff@(posedge clk or posedge reset)
    if(reset) state <= INIT_STATE;
    else state <= next_state;

always_comb
begin
    case(state)
    INIT_STATE: next_state = BUFFER_STATE;
    WRITE_TO_MEM: next_state = CHECK_IF_DONE;
    CHECK_IF_DONE:  if(finish) next_state = IDLE;
                    else next_state = INCREMENT_COUNT;
    INCREMENT_COUNT: next_state = BUFFER_STATE;
    BUFFER_STATE: next_state = WRITE_TO_MEM;
    IDLE: next_state = IDLE;
    default: next_state = INIT_STATE;
    endcase
end

////////// Combational logic for some inputs to the state machine/////
assign finish = (counter_value == 8'hFF);

/////////////////// Output Logic /////////////////
assign wren = state[0];
assign count_enable = state[1];
assign address = counter_value;
assign data = counter_value;
assign done = state[4];

endmodule

//////////////// Counter ////////////////////////
module counter
#(parameter N = 8)
(
            input logic clk, reset,count_enable,
            output logic [N-1:0] q
);

initial q = 0;

always_ff@(posedge clk, posedge reset)
begin
    if(reset)   q <= 0;
    else if(count_enable) q <= q + 1'b1;
end

endmodule