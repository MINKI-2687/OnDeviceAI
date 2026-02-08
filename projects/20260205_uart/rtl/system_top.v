`timescale 1ns / 1ps

module system_top (
    input         clk,
    input         rst,
    input  [15:0] sw,
    input         btn_r,
    input         btn_l,
    input         btn_u,
    input         btn_d,
    input         uart_rx,
    output        uart_tx,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    output [15:0] led
);
    // uart rx_data, done
    wire [7:0] w_rx_data;
    wire w_rx_done;

    // wire uart btn, sw for physical btn, sw (OR gate)
    wire w_uart_btn_r, w_uart_btn_l, w_uart_btn_u, w_uart_btn_d;
    wire w_uart_sw_mode, w_uart_sw_sel_mode, w_uart_sw_sel_display;

    // debounced btn
    wire w_btn_r, w_btn_l, w_btn_u, w_btn_d;

    // combine btn, sw (OR gate)
    wire w_comb_r, w_comb_l, w_comb_u, w_comb_d;
    wire w_comb_mode, w_comb_sel_mode, w_comb_sel_display;

    // to control unit
    assign w_comb_r           = w_uart_btn_r | w_btn_r;
    assign w_comb_l           = w_uart_btn_l | w_btn_l;
    assign w_comb_u           = w_uart_btn_u | w_btn_u;
    assign w_comb_d           = w_uart_btn_d | w_btn_d;
    assign w_comb_mode        = w_uart_sw_mode ^ sw[0];
    assign w_comb_sel_mode    = w_uart_sw_sel_mode ^ sw[1];
    assign w_comb_sel_display = w_uart_sw_sel_display ^ sw[2];

    // down count
    assign led[0]             = w_comb_mode;
    // watch mode -> led[1] ON
    assign led[1]             = w_comb_sel_mode;
    // other led
    assign led[15:2]          = 14'b0;

    // watch control unit -> datapath
    wire w_ctrl_watch_mode, w_ctrl_watch_run, w_ctrl_watch_clear;
    wire w_h_digit, w_m_digit, w_s_digit, w_ms_digit;

    // stopwatch control unit -> datapath
    wire w_ctrl_sw_mode, w_ctrl_sw_run_stop, w_ctrl_sw_clear;

    // time data
    wire [23:0] w_time_data;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_r),
        .o_btn(w_btn_r)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_l),
        .o_btn(w_btn_l)
    );

    btn_debounce U_BD_UP (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_u),
        .o_btn(w_btn_u)
    );

    btn_debounce U_BD_DOWN (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_d),
        .o_btn(w_btn_d)
    );

    uart_top U_UART_TOP (
        .clk    (clk),
        .rst    (rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    ascii_decoder U_ASCII_DECODER (
        .clk                (clk),
        .rst                (rst),
        .rx_data            (w_rx_data),             // from uart_rx
        .rx_done            (w_rx_done),             // rx complete signal
        // from uart input (r, l, u, d)
        .uart_btn_r         (w_uart_btn_r),          // run_stop
        .uart_btn_l         (w_uart_btn_l),          // clear
        .uart_btn_u         (w_uart_btn_u),          // up
        .uart_btn_d         (w_uart_btn_d),          // down
        // from uart input (sw[0], [1], [2])
        .uart_sw_mode       (w_uart_sw_mode),
        .uart_sw_sel_mode   (w_uart_sw_sel_mode),
        .uart_sw_sel_display(w_uart_sw_sel_display)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk         (clk),
        .reset       (rst),
        .i_setting   (sw[3]),
        .i_digit_sel (sw[15:12]),
        .i_btn_up    (w_comb_u),            // up setting
        .i_btn_down  (w_comb_d),            // down setting
        .i_mode      (w_comb_mode),
        .i_mode_sel  (w_comb_sel_mode),
        .i_run       (w_comb_r),
        .i_clear     (w_comb_l),
        .o_mode      (w_ctrl_watch_mode),
        .o_run       (w_ctrl_watch_run),
        .o_clear     (w_ctrl_watch_clear),
        .o_hour_digit(w_h_digit),
        .o_min_digit (w_m_digit),
        .o_sec_digit (w_s_digit),
        .o_msec_digit(w_ms_digit)
    );

    sw_control_unit U_SW_CONTROL_UNIT (
        .clk       (clk),
        .reset     (rst),
        .i_mode    (w_comb_mode),
        .i_mode_sel(w_comb_sel_mode),
        .i_run_stop(w_comb_r),
        .i_clear   (w_comb_l),
        .o_mode    (w_ctrl_sw_mode),
        .o_run_stop(w_ctrl_sw_run_stop),
        .o_clear   (w_ctrl_sw_clear)
    );

    sw_watch_data U_SW_WATCH_DATA (
        .clk        (clk),
        .reset      (rst),
        // watch control
        .w_mode     (w_ctrl_watch_mode),
        .w_run_stop (w_ctrl_watch_run),
        .w_clear    (w_ctrl_watch_clear),
        .w_h_digit  (w_h_digit),
        .w_m_digit  (w_m_digit),
        .w_s_digit  (w_s_digit),
        .w_ms_digit (w_ms_digit),
        // stopwatch control
        .sw_mode    (w_ctrl_sw_mode),
        .sw_run_stop(w_ctrl_sw_run_stop),
        .sw_clear   (w_ctrl_sw_clear),
        // stopwatch, watch mode select
        .sel_mode   (w_comb_sel_mode),
        // output
        .time_data  (w_time_data)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (rst),
        .sel_display(w_comb_sel_display),
        .fnd_in_data(w_time_data),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule
