`timescale 1ns / 1ps

module pattern_detect (
    input      clk,
    input      rst,
    input      din_bit,
    output reg dout_bit
);

    // state define
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10, S3 = 2'b11;

    // state variable 
    reg [1:0] current_st, next_st;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_st <= S0;
        end else begin
            current_st <= next_st;
        end
    end

    // next_state CL
    always @(*) begin
        next_st  = current_st;
        dout_bit = 1'b0;
        case (current_st)
            S0: begin
                if (!din_bit) begin
                    dout_bit = 1'b0;
                    next_st  = S1;
                end else begin
                    next_st = S0;
                end
            end
            S1: begin
                if (din_bit) begin
                    dout_bit = 1'b0;
                    next_st  = S2;
                end else begin
                    next_st = S1;
                end
            end
            S2: begin
                if (!din_bit) begin
                    dout_bit = 1'b0;
                    next_st  = S3;
                end else begin
                    next_st = S0;
                end
            end
            S3: begin
                if (din_bit) begin
                    dout_bit = 1'b1;
                    next_st  = S0;
                end else begin
                    dout_bit = 1'b0;
                    next_st  = S1;
                end
            end
        endcase
    end

endmodule
