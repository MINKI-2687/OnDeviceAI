`timescale 1ns / 1ps

module fnd_controller (
    input         clk,
    input         reset,
    input  [13:0] fnd_in_data,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data
);

    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_mux_4x1_out;
    wire [1:0] w_digit_sel;
    wire w_1khz;

    digit_splitter U_DIGIT_SPL (
        .in_data   (fnd_in_data),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000)
    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .reset (reset),
        .o_1khz(w_1khz)
    );
    counter_4 U_COUNTER_4 (
        .clk      (w_1khz),
        .reset    (reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel  (w_digit_sel),
        .decoder_out(fnd_digit)
    );

    mux_4x1 U_MUX_4x1 (
        .sel       (w_digit_sel),
        .digit_1   (w_digit_1),
        .digit_10  (w_digit_10),
        .digit_100 (w_digit_100),
        .digit_1000(w_digit_1000),
        .mux_out   (w_mux_4x1_out)
    );

    bcd U_BCD (
        .bcd     (w_mux_4x1_out),
        .fnd_data(fnd_data)
    );

endmodule
