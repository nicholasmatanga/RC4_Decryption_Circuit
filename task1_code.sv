`default_nettype none
module init_s_memory_state_machine(
        input logic clk,
        output logic [7:0] address, data,
        output logic wren
);

logic count_enable,finish;
logic [7:0] counter_value;
logic [3:0] state, next_state;

//////////// State encodings ///////////////
parameter [3:0] IDLE = 4'b00_00,
                WRITE_TO_MEM = 4'b00_01,
                INCREMENT_COUNT = 4'b00_10,
                CHECK_IF_DONE = 4'b01_00,
                BUFFER_STATE = 4'b10_00;

///// Specifying starting state of the state machine /////////
initial state = WRITE_TO_MEM;

////// Counter instantiation which increments values sent to memory ////////////
counter send_to_s(
    .clk(clk),
    .reset(1'b0),
    .count_enable(count_enable),
    .q(counter_value)
);

/////// State register //////////////////
always_ff@(posedge clk)
   state <= next_state;

always_comb
begin
    case(state)
    IDLE: next_state = IDLE;

    WRITE_TO_MEM: next_state = CHECK_IF_DONE;
    CHECK_IF_DONE:  if(finish) next_state = IDLE;
                    else next_state = INCREMENT_COUNT;
    INCREMENT_COUNT: next_state = BUFFER_STATE;
    BUFFER_STATE: next_state = WRITE_TO_MEM;
    default: next_state = WRITE_TO_MEM;
    endcase
end

////////// Combational logic for some inputs to the state machine/////
assign finish = (counter_value == 8'hFF);

/////////////////// Output Logic /////////////////
assign wren = state[0];
assign count_enable = state[1];
assign address = counter_value;
assign data = counter_value;

endmodule

//////////////// Counter ////////////////////////
module counter (
            input logic clk, reset,count_enable,
            output logic [7:0] q
);

initial q = 8'b0;

always_ff@(posedge clk, posedge reset)
begin
    if(reset)   q<=0;
    else if(count_enable) q <= q + 1;
end

endmodule