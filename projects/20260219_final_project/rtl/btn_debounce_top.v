`timescale 1ns / 1ps

module btn_debounce_top (
    input  clk,
    input  rst,
    input  btn_r,
    input  btn_l,
    input  btn_u,
    input  btn_d,
    output o_btn_r,
    output o_btn_l,
    output o_btn_u,
    output o_btn_d
);

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_r),
        .o_btn(o_btn_r)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_l),
        .o_btn(o_btn_l)
    );

    btn_debounce U_BD_UP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_u),
        .o_btn(o_btn_u)
    );

    btn_debounce U_BD_DOWN (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_d),
        .o_btn(o_btn_d)
    );

endmodule
