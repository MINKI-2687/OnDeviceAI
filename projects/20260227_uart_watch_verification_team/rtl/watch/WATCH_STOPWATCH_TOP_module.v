`timescale 1ns / 1ps

module WATCH_STOPWATCH_Top_module (
    input       clk,
    input       reset,
    input       btn_L,
    input       btn_R,
    input       btn_C,
    input       btn_U,
    input       btn_D,
    input [2:0] sw,
    //Uart
    input       uart_btn_L,
    input       uart_btn_R,
    input       uart_btn_C,
    input       uart_btn_U,
    input       uart_btn_D,
    input       uart_sw_0,
    input       uart_sw_1,
    input       uart_sw_2,

    //FND
    output [3:0] fnd_digit,
    output [7:0] fnd_data,

    // to ASCII SENDDER
    output [4:0] o_hour,
    output [5:0] o_min,
    output [5:0] o_sec,

    output [1:0] led
);

    wire w_btn_L, w_btn_R, w_btn_C, w_btn_U, w_btn_D;
    wire w_btn_U_level, w_btn_D_level, w_btn_U_level_gated, w_btn_D_level_gated;
    wire w_sw_run_stop, w_sw_clear, w_sw_mode;
    wire [2:0] w_w_cursor;
    wire w_w_blink_en;
    wire [6:0] w_out_msec;
    wire [5:0] w_out_sec;
    wire [5:0] w_out_min;
    wire [4:0] w_out_hour;
    wire [23:0] w_time_data_packed;

    reg [25:0] blink_cnt;
    wire w_blink_off;
    reg [3:0] w_blink_mask;  // ★ FND에게 보낼 "끄기 명령" 신호

    btn U_BTN (
        .clk          (clk),
        .reset        (reset),
        .i_btn_L      (btn_L),
        .i_btn_R      (btn_R),
        .i_btn_C      (btn_C),
        .i_btn_U      (btn_U),
        .i_btn_D      (btn_D),
        .o_btn_L      (w_btn_L),
        .o_btn_R      (w_btn_R),
        .o_btn_C      (w_btn_C),
        .o_btn_U      (w_btn_U),
        .o_btn_D      (w_btn_D),
        .o_btn_U_level(w_btn_U_level),
        .o_btn_D_level(w_btn_D_level)
    );

    // 물리 스위치와 UART PC 스위치 입력 결합
    wire [2:0] w_final_sw;

    // [수정됨] sw[2] 대신 합쳐진 w_final_sw[2] 사용
    assign led = (w_final_sw[2]) ? 2'b01 : 2'b11;

    assign w_final_sw[0] = sw[0] | uart_sw_0;
    assign w_final_sw[1] = sw[1] | uart_sw_1;
    assign w_final_sw[2] = sw[2] | uart_sw_2;

    assign w_btn_U_level_gated = (w_final_sw[2] == 1'b1) ? 1'b0 : (w_btn_U_level | uart_btn_U);
    assign w_btn_D_level_gated = (w_final_sw[2] == 1'b1) ? 1'b0 : (w_btn_D_level | uart_btn_D);

    control_unit U_TOP_CTRL (
        .clk                 (clk),
        .reset               (reset),
        .i_sw_watch_stopwatch(w_final_sw[2]),
        .i_sw_up_down        (w_final_sw[0]),
        .i_btn_L             (w_btn_L | uart_btn_L),
        .i_btn_R             (w_btn_R | uart_btn_R),
        .i_btn_C             (w_btn_C | uart_btn_C),
        .o_sw_run_stop       (w_sw_run_stop),
        .o_sw_clear          (w_sw_clear),
        .o_sw_mode           (w_sw_mode),
        .o_w_cursor          (w_w_cursor),
        .o_w_blink_en        (w_w_blink_en)
    );

    data_path U_TOP_DP (
        .clk               (clk),
        .reset             (reset),
        // [수정됨] 합쳐진 스위치 사용
        .i_watch_stopwatch (w_final_sw[2]),
        .i_sw_mode         (w_sw_mode),
        .i_sw_run_stop     (w_sw_run_stop),
        .i_sw_clear        (w_sw_clear),
        .i_w_cursor        (w_w_cursor),
        .i_w_btn_up_level  (w_btn_U_level_gated),
        .i_w_btn_down_level(w_btn_D_level_gated),
        .o_msec            (w_out_msec),
        .o_sec             (w_out_sec),
        .o_min             (w_out_min),
        .o_hour            (w_out_hour)
    );

    assign o_hour = w_out_hour;
    assign o_min = w_out_min;
    assign o_sec = w_out_sec;

    assign w_time_data_packed = {w_out_hour, w_out_min, w_out_sec, w_out_msec};

    // 깜빡임 타이머
    always @(posedge clk) blink_cnt <= blink_cnt + 1;
    assign w_blink_off = blink_cnt[25];

    // ★ 마스크 신호 생성 (이걸로 깜빡임을 제어)
    always @(*) begin
        w_blink_mask = 4'b0000;
        // [수정됨] sw[2] -> w_final_sw[2]로 변경
        if (w_final_sw[2] == 1'b0 && w_w_blink_en && w_blink_off) begin
            case (w_w_cursor)
                // 시(Hour) 수정 중일 때 (커서가 1이든 2든) -> 앞의 두 자리(Hour)를 다 끔
                3'd1: w_blink_mask = 4'b1100;  // Hour 10, Hour 1 둘 다 Mask
                3'd2: w_blink_mask = 4'b1100;  // Hour 10, Hour 1 둘 다 Mask
                // 분(Min) 수정 중일 때 (커서가 3이든 4든) -> 뒤의 두 자리(Min)를 다 끔
                3'd3: w_blink_mask = 4'b0011;  // Min 10, Min 1 둘 다 Mask
                3'd4: w_blink_mask = 4'b0011;  // Min 10, Min 1 둘 다 Mask

                default: w_blink_mask = 4'b0000;
            endcase
        end
    end

    // FND Controller (마스크 입력 포트 연결)
    FND_CNTL #(
        .BIT_WIDTH(3)
    ) U_FND_CNTL (
        .clk         (clk),
        .reset       (reset),
        // [수정됨] 합쳐진 스위치 사용
        .sel_display (w_final_sw[1]),
        .i_count     (w_time_data_packed),  // 데이터는 원본 그대로!
        .i_blink_mask(w_blink_mask),        // 명령은 따로!
        .fnd_digit   (fnd_digit),
        .fnd_data    (fnd_data)
    );

endmodule
