`timescale 1ns / 1ps

module data_path (
    input clk,
    input reset,
    
    // --- 출력 선택 신호 ---
    input i_watch_stopwatch, // sw[2]: 0=Watch(시계), 1=Stopwatch(스톱와치)

    // --- 스톱와치용 입력 신호 (From Control Unit) ---
    input i_sw_mode,      // Up/Down Count Mode
    input i_sw_run_stop,  // Run/Stop Signal
    input i_sw_clear,     // Clear Signal

    // --- 와치용 입력 신호 (From Control Unit & Top) ---
    input [2:0] i_w_cursor,     // 커서 위치 (Control Unit에서 옴)
    input i_w_btn_up_level,     // ★ Gated Level Input (Top에서 옴)
    input i_w_btn_down_level,   // ★ Gated Level Input (Top에서 옴)

    // --- 최종 출력 (To FND Controller) ---
    output reg [6:0] o_msec,
    output reg [5:0] o_sec,
    output reg [5:0] o_min,
    output reg [4:0] o_hour
);

    // --------------------------------------------------------
    // 1. 내부 와이어 선언 (각 모듈의 출력을 받을 변수들)
    // --------------------------------------------------------
    // 스톱와치 데이터
    wire [6:0] sw_msec;
    wire [5:0] sw_sec;
    wire [5:0] sw_min;
    wire [4:0] sw_hour;

    // 와치 데이터
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    // --------------------------------------------------------
    // 2. 모듈 인스턴스화
    // --------------------------------------------------------

    // (1) 스톱와치 데이터패스
    StopWatch_Datapath U_SW_DP (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (i_sw_mode),
        .i_run_stop(i_sw_run_stop),
        .i_clear   (i_sw_clear),
        .o_msec    (sw_msec),
        .o_sec     (sw_sec),
        .o_min     (sw_min),
        .o_hour    (sw_hour)
    );

    // (2) 와치 데이터패스 (내부에 가속기 포함됨)
    Watch_Datapath U_WATCH_DP (
        .clk       (clk),
        .reset     (reset),
        .i_cursor  (i_w_cursor),
        .i_btn_up  (i_w_btn_up_level),   // 꾹 누르는 신호 (Gated) 연결
        .i_btn_down(i_w_btn_down_level), // 꾹 누르는 신호 (Gated) 연결
        .o_hour    (w_hour),
        .o_min     (w_min),
        .o_sec     (w_sec),
        .o_msec    (w_msec)
    );

    // --------------------------------------------------------
    // 3. 출력 MUX (화면 표시 데이터 선택)
    // --------------------------------------------------------
    // sw[2]가 1이면 스톱와치 데이터, 0이면 와치 데이터를 내보냄
    always @(*) begin
        if (i_watch_stopwatch == 1'b1) begin
            // [스톱와치 모드]
            o_msec = sw_msec;
            o_sec  = sw_sec;
            o_min  = sw_min;
            o_hour = sw_hour;
        end else begin
            // [시계 모드]
            o_msec = w_msec;
            o_sec  = w_sec;
            o_min  = w_min;
            o_hour = w_hour;
        end
    end

endmodule