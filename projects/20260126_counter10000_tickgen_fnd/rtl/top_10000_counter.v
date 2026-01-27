`timescale 1ns / 1ps

module top_10000_counter (
    input        clk,
    input        reset,
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_tick_10hz;

    tick_gen_10hz U_TICK_GEN (
        .clk        (clk),
        .reset      (reset),
        .o_tick_10hz(w_tick_10hz)
    );

    counter_10000 U_COUNTER_10000 (
        .clk    (clk),
        .reset  (reset),
        .i_tick (w_tick_10hz),
        .counter(w_counter)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data(w_counter),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module tick_gen_10hz (
    input      clk,
    input      reset,
    output reg o_tick_10hz
);

    reg [$clog2(10_000_000)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter   <= 0;
            o_tick_10hz <= 1'b0;
        end else begin
            r_counter   <= r_counter + 1;
            o_tick_10hz <= 1'b0;
            if (r_counter == (10_000_000 - 1)) begin
                r_counter   <= 0;
                o_tick_10hz <= 1'b1;
            end else begin
                o_tick_10hz <= 1'b0;
            end
        end
    end

endmodule

module counter_10000 (
    input         clk,
    input         reset,
    input         i_tick,
    output [13:0] counter
);

    reg [13:0] r_counter;

    assign counter = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 14'd0;
        end else begin
            if (i_tick) begin
                r_counter <= r_counter + 1;
            end
            if (r_counter == 9999) begin
                r_counter <= 14'd0;
            end
        end
    end

endmodule
