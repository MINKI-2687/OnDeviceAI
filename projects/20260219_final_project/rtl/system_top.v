`timescale 1ns / 1ps

module system_top (
    input         clk,
    input         rst,
    input  [15:0] sw,
    //input         uart_rx,
    input         btn_r,
    input         btn_l,
    input         btn_u,
    input         btn_d,
    input         echo,
    output        o_trigger,
    inout         dhtio,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    // output        uart_tx,
    output [15:0] led
);

    // btn
    wire o_btn_r, o_btn_l, o_btn_u, o_btn_d;

    // dot : 초음파 센서가 아닐 때만 dot가 1이 됨
    wire w_dot = (sw[5:4] != 2'b01);

    // 각 모듈 데이터 수집용 wire
    wire [31:0] w_clock_data;  // 시계 데이터
    wire [8:0] w_sr04_data;  // 초음파 데이터
    wire [15:0] w_humidity, w_temperature;
    reg [31:0] final_fnd;  // FND로 보낼 최종 16비트

    always @(*) begin
        case (sw[5:4])
            2'b00: final_fnd = w_clock_data;
            2'b01: begin
                final_fnd[31:16] = 16'h0000;      // 상위 비트는 0 (거울모드 쓰려면 여기에 똑같이 복사)
                final_fnd[15:8] = w_sr04_data / 100;  // 백의 자리
                final_fnd[7:0] = w_sr04_data % 100;  // 십/일의 자리
            end
            2'b10:
            final_fnd = {16'h0000, w_humidity[15:8], w_temperature[15:8]};
            default: final_fnd = 32'h0000_0000;
        endcase
    end

    btn_debounce_top U_BTN_DEBOUNCE (
        .clk    (clk),
        .rst    (rst),
        .btn_r  (btn_r),
        .btn_l  (btn_l),
        .btn_u  (btn_u),
        .btn_d  (btn_d),
        .o_btn_r(o_btn_r),
        .o_btn_l(o_btn_l),
        .o_btn_u(o_btn_u),
        .o_btn_d(o_btn_d)
    );

    /*uart_top U_UART_FIFO (
        .clk    (clk),
        .rst    (rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx)
    );*/

    top_stopwatch_watch U_SW_WATCH (
        .clk         (clk),
        .rst         (rst),
        .sw          (sw),
        .btn_up      (o_btn_u),
        .btn_down    (o_btn_d),
        .btn_run_stop(o_btn_r),
        .btn_clear   (o_btn_l),
        .o_watch_data(w_clock_data)
    );

    controller_SR04 U_CNTL_SR04 (
        .clk      (clk),
        .rst      (rst),
        .btn_r    (o_btn_r),
        .echo     (echo),
        .o_trigger(o_trigger),
        .distance (w_sr04_data)
    );

    dht11_controller U_DHT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .start      (o_btn_r),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .dht11_done (led[12]),
        .dht11_valid(led[11]),
        .debug      (led[15:13]),
        .dhtio      (dhtio)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .rst        (rst),
        .sel_display(sw[2]),
        .dot        (w_dot),
        .fnd_in_data(final_fnd),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule
