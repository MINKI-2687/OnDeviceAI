`timescale 1ns / 1ps

module fsm_mealy (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);
    reg [2:0] state_reg, next_state;

    // state define
    parameter start     = 3'b000;
    parameter rd0_once  = 3'b001;
    parameter rdl_once  = 3'b010;
    parameter rd0_twice = 3'b011;
    parameter rdl_twice = 3'b100;

    // next state CL
    always @(state_reg or din_bit) begin
        case (state_reg)
            start:      if      (din_bit == 0) next_state = rd0_once;
                        else if (din_bit == 1) next_state = rdl_once;
                        else                   next_state = start;
            rd0_once:   if      (din_bit == 0) next_state = rd0_twice;
                        else if (din_bit == 1) next_state = rdl_once;
                        else                   next_state = start;
            rd0_twice:  if      (din_bit == 0) next_state = rd0_twice;
                        else if (din_bit == 1) next_state = rdl_once;
                        else                   next_state = start;
            rdl_once:   if      (din_bit == 0) next_state = rd0_once;
                        else if (din_bit == 1) next_state = rdl_twice;
                        else                   next_state = start;
            rdl_twice:  if      (din_bit == 0) next_state = rd0_once;
                        else if (din_bit == 1) next_state = rdl_twice;
                        else                   next_state = start;
            default:                           next_state = start;
        endcase
    end

    // state register SL
    always @(posedge clk or posedge rst) begin
        if (rst == 1) state_reg <= start;
        else          state_reg <= next_state;
    end

    // output CL
    assign dout_bit =(((state_reg == rd0_twice) && (din_bit == 0) ||
                        (state_reg == rdl_twice) && (din_bit == 1))) ? 1 : 0;

endmodule
