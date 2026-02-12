module sensor_top (
    input         clk,
    input         rst,
    input         btn_r,
    input         echo,
    output        o_trigger,
    output [23:0] distance
);
    wire w_tick_1us;

    controller_SR04 U_CTRL (
        .clk       (clk),
        .rst       (rst),
        .btn_r     (btn_r),
        .i_tick_1us(w_tick_1us),
        .echo      (echo),
        .o_trigger (o_trigger),
        .distance  (distance)
    );

    tick_gen_1Mhz U_TICK_GEN (
    .clk(clk),
    .rst(rst),
    .o_tick_1Mhz(w_tick_1us)
);

endmodule
