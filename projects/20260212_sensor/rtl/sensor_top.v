module sensor_top (
    input         clk,
    input         rst,
    input         btn_r,
    input         echo,
    output        o_trigger
    //output [23:0] distance
);
    wire w_btn_r, w_tick_1us;
    wire [23:0] w_distance;

    controller_SR04 U_CTRL (
        .clk       (clk),
        .rst       (rst),
        .btn_r     (w_btn_r),
        .i_tick_1us(w_tick_1us),
        .echo      (echo),
        .o_trigger (o_trigger),
        .distance  (w_distance)
    );

    tick_gen_1Mhz U_TICK_GEN (
        .clk        (clk),
        .rst        (rst),
        .o_tick_1Mhz(w_tick_1us)
    );

    btn_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_r),
        .o_btn(w_btn_r)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sel_display(),
        .fnd_in_data(w_distance),
        .fnd_digit  (),
        .fnd_data   ()
    );

endmodule
