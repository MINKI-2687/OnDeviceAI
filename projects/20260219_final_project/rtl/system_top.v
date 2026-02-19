`timescale 1ns / 1ps

module system_top (
    input         clk,
    input         rst,
    input  [15:0] sw,         //
    input         btn_r,
    input         btn_l,
    input         btn_u,
    input         btn_d,
    input         echo,
    output        o_trigger,
    inout         dhtio,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    output [ 3:0] led_debug   // 상태 표시용
);

    // btn
    wire o_btn_run, o_btn_clear, o_btn_up, o_btn_down;

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

    // 온습도 센서 2초 자동 업데이트용 타이머
    reg [27:0] dht_timer;
    wire w_dht_auto_start;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dht_timer <= 0;
        end else begin
            // 200,000,000번 카운트 = 2초
            if (dht_timer >= 200_000_000) begin
                dht_timer <= 0;
            end else begin
                dht_timer <= dht_timer + 1;
            end
        end
    end

    // 타이머가 0이 되는 딱 한 순간(1클럭)에만 펄스(1) 발생
    assign w_dht_auto_start = (dht_timer == 0) ? 1'b1 : 1'b0;

    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_r),
        .o_btn(o_btn_run)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );

    btn_debounce U_BD_UP (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_u),
        .o_btn(o_btn_up)
    );

    btn_debounce U_BD_DOWN (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_d),
        .o_btn(o_btn_down)
    );

    top_stopwatch_watch U_SW_WATCH (
        .clk         (clk),
        .rst         (rst),
        .sw          (sw),           // 스위치 입력
        .btn_up      (o_btn_up),     // 디바운싱 버튼
        .btn_down    (o_btn_down),
        .btn_run_stop(o_btn_run),
        .btn_clear   (o_btn_clear),
        .o_watch_data(w_clock_data)
    );

    controller_SR04 U_CNTL_SR04 (
        .clk      (clk),
        .rst      (rst),
        .btn_r    (o_btn_run),   // start
        .echo     (echo),
        .o_trigger(o_trigger),
        .distance (w_sr04_data)
    );

    dht11_controller U_DHT11_CNTL (
        .clk        (clk),
        .rst        (rst),
        .start      (o_btn_run | w_dht_auto_start),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .dht11_done (led_debug[0]),
        .dht11_valid(led_debug[1]),
        .debug      (led_debug[3:2]),
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
