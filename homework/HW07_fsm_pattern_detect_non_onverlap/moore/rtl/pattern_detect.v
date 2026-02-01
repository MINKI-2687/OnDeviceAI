`timescale 1ns / 1ps

module pattern_detect (
    input  clk,
    input  rst,
    input  din_bit,
    output dout_bit
);

    // state define
    parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100;

    // state variable
    reg [2:0] current_st, next_st;

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_st <= S0;
        end else begin
            current_st <= next_st;
        end
    end

    // next state CL
    always @(*) begin
        next_st = current_st;
        case (current_st)
            S0: begin
                if (!din_bit) begin
                    next_st = S1;
                end
            end
            S1: begin
                if (din_bit) begin
                    next_st = S2;
                end
            end
            S2: begin
                if (!din_bit) begin
                    next_st = S3;
                end else begin
                    next_st = S0;
                end
            end
            S3: begin
                if (din_bit) begin
                    next_st = S4;
                end else begin
                    next_st = S1;
                end
            end
            S4: begin
                if (din_bit) begin
                    next_st = S0;
                end else begin
                    next_st = S1;
                end
            end
        endcase
    end

    // output CL
    assign dout_bit = (current_st == S4) ? 1'b1 : 1'b0;

endmodule
