`timescale 1ns / 1ps

module Top_module (
    input clk,
    input reset,
    //물리버튼
    input btn_L,
    input btn_R,
    input btn_C,
    input btn_U,
    input btn_D,
    input [2:0] sw,
    // UART
    input i_uart_rx,
    output o_uart_tx,
    //FND
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output [1:0] led
);

    // UART 수신 데이터
    wire [7:0] w_o_rx_data;
    wire w_o_rx_done;

    // Sender -> UART TX 연결용 와이어
    wire [7:0] w_sender_tx_data;
    wire w_sender_tx_start;
    wire w_tx_busy;
    wire w_sender_active;

    // [최종] UART TX로 들어갈 신호
    wire [7:0] w_final_tx_data;
    wire w_final_tx_start;

    // Watch -> Sender 시간 정보
    wire [4:0] w_cur_hour;
    wire [5:0] w_cur_min;
    wire [5:0] w_cur_sec;

    // Decoder -> Sender 트리거
    wire w_send_trig;

    // 아스키 디코더 출력 
    wire u_btn_L, u_btn_R, u_btn_C, u_btn_U, u_btn_D;
    wire u_sw_0, u_sw_1, u_sw_2;


    assign w_final_tx_data = (w_sender_active) ? w_sender_tx_data : w_o_rx_data;

    assign w_final_tx_start = (w_sender_active) ? w_sender_tx_start : 
                              (w_o_rx_done && (w_o_rx_data != 8'h70) && (w_o_rx_data != 8'h50));

    // 1. UART 모듈
    UART_Top_Module U_UART (
        .clk       (clk),
        .reset     (reset),
        .i_tx_data (w_final_tx_data),
        .i_tx_start(w_final_tx_start),
        .i_uart_rx (i_uart_rx),
        .o_uart_tx (o_uart_tx),
        .o_tx_busy (w_tx_busy),
        .o_rx_data (w_o_rx_data),
        .o_rx_done (w_o_rx_done)
    );

    // 2. 아스키 디코더
    ascii2btn_decoder U_ASCII_DECODER (
        .clk        (clk),
        .reset      (reset),
        .i_rx_done  (w_o_rx_done),
        .i_rx_data  (w_o_rx_data),
        .o_btn_L    (u_btn_L),
        .o_btn_R    (u_btn_R),
        .o_btn_C    (u_btn_C),
        .o_btn_U    (u_btn_U),
        .o_btn_D    (u_btn_D),
        .o_sw_0     (u_sw_0),
        .o_sw_1     (u_sw_1),
        .o_sw_2     (u_sw_2),
        .o_send_trig(w_send_trig)
    );

    // 3. ASCII Sender
    ASCII_Sender U_ASCII_SENDER (
        .clk               (clk),
        .reset             (reset),
        .i_send_trig       (w_send_trig),
        .i_tx_busy         (w_tx_busy),
        .i_hour            (w_cur_hour),
        .i_min             (w_cur_min),
        .i_sec             (w_cur_sec),
        .o_send_to_tx_data (w_sender_tx_data),
        .o_send_to_tx_start(w_sender_tx_start),
        .o_is_sending      (w_sender_active)
    );

    // 4. Watch System
    WATCH_STOPWATCH_Top_module U_WATCH_STOPWATCH (
        .clk       (clk),
        .reset     (reset),
        .btn_L     (btn_L),
        .btn_R     (btn_R),
        .btn_C     (btn_C),
        .btn_U     (btn_U),
        .btn_D     (btn_D),
        .sw        (sw),
        .uart_btn_L(u_btn_L),
        .uart_btn_R(u_btn_R),
        .uart_btn_C(u_btn_C),
        .uart_btn_U(u_btn_U),
        .uart_btn_D(u_btn_D),
        .uart_sw_0 (u_sw_0),
        .uart_sw_1 (u_sw_1),
        .uart_sw_2 (u_sw_2),
        .fnd_digit (fnd_digit),
        .fnd_data  (fnd_data),


        .o_hour(w_cur_hour),
        .o_min (w_cur_min),
        .o_sec (w_cur_sec),
        .led   (led)
    );

endmodule
