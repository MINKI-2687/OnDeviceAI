`timescale 1ns / 1ps

module top_stopwatch_watch (
    input         clk,
    input         rst,
    input  [15:0] sw,            // 스위치 입력
    input         btn_up,        // 디바운싱 버튼
    input         btn_down,
    input         btn_run_stop,
    input         btn_clear,
    output [31:0] o_watch_data,
    output [15:0] led
);

    // control watch
    wire w_ctrl_watch_mode, w_ctrl_watch_run_stop, w_ctrl_watch_clear;
    wire w_h_digit, w_m_digit, w_s_digit, w_ms_digit;

    // control stopwatch
    wire w_ctrl_sw_run_stop, w_ctrl_sw_clear;

    wire [31:0] w_stopwatch_time;
    wire [31:0] w_watch_time;
    wire [31:0] w_time_data;

    wire w_i_mode_sel;

    assign o_watch_data = w_time_data;

    assign led[0] = sw[0];
    assign led[1] = w_i_mode_sel;

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk         (clk),
        .rst         (rst),
        .i_setting   (sw[3]),
        .i_digit_sel (sw[15:12]),
        .i_btn_up    (btn_up),                 // up setting
        .i_btn_down  (btn_down),               // down setting
        .i_mode      (sw[0]),
        .i_mode_sel  (sw[1]),
        .i_run       (btn_run_stop),
        .i_clear     (btn_clear),
        .o_mode      (w_ctrl_watch_mode),
        .o_run       (w_ctrl_watch_run_stop),
        .o_clear     (w_ctrl_watch_clear),
        .o_hour_digit(w_h_digit),
        .o_min_digit (w_m_digit),
        .o_sec_digit (w_s_digit),
        .o_msec_digit(w_ms_digit)
    );

    sw_control_unit U_SW_CONTROL_UNIT (
        .clk       (clk),
        .rst       (rst),
        .i_mode    (sw[0]),
        .i_mode_sel(sw[1]),
        .i_run_stop(btn_run_stop),
        .i_clear   (btn_clear),
        .o_mode    (w_ctrl_sw_mode),
        .o_run_stop(w_ctrl_sw_run_stop),
        .o_clear   (w_ctrl_sw_clear)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk     (clk),
        .rst     (rst),
        .mode    (w_ctrl_watch_mode),
        .run_stop(w_ctrl_watch_run_stop),
        .clear   (w_ctrl_watch_clear),
        .h_digit (w_h_digit),
        .m_digit (w_m_digit),
        .s_digit (w_s_digit),
        .ms_digit(w_ms_digit),
        .msec    (w_watch_time[7:0]),
        .sec     (w_watch_time[15:8]),
        .min     (w_watch_time[23:16]),
        .hour    (w_watch_time[31:24])
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .rst     (rst),
        .mode    (w_ctrl_sw_mode),
        .run_stop(w_ctrl_sw_run_stop),
        .clear   (w_ctrl_sw_clear),
        .msec    (w_stopwatch_time[7:0]),    // 7bit
        .sec     (w_stopwatch_time[15:8]),   // 6bit
        .min     (w_stopwatch_time[23:16]),  // 6bit
        .hour    (w_stopwatch_time[31:24])   // 5bit
    );

    mux_2x1_watch_stopwatch U_MUX_MODE_SELCET (
        .sel   (sw[1]),
        .i_sel0(w_stopwatch_time),
        .i_sel1(w_watch_time),
        .o_mux (w_time_data)
    );

endmodule

module watch_datapath (
    input        clk,
    input        rst,
    input        mode,
    input        run_stop,
    input        clear,
    input        h_digit,
    input        m_digit,
    input        s_digit,
    input        ms_digit,
    output [7:0] msec,
    output [7:0] sec,
    output [7:0] min,
    output [7:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // 내부 카운터 출력용 wire 선언
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    assign msec = {1'b0, w_msec};
    assign sec  = {2'b0, w_sec};
    assign min  = {2'b0, w_min};
    assign hour = {3'b0, w_hour};

    // hour
    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24),
        .INIT_VAL (12)
    ) hour_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_hour_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(h_digit),
        .o_count       (hour),
        .o_tick        ()
    );

    // min
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_min_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(m_digit),
        .o_count       (min),
        .o_tick        (w_hour_tick)
    );

    // sec
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_sec_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(s_digit),
        .o_count       (sec),
        .o_tick        (w_min_tick)
    );

    // msec
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_tick_100hz),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(ms_digit),
        .o_count       (msec),
        .o_tick        (w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .rst         (rst),
        .i_run_stop  (run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module stopwatch_datapath (
    input        clk,
    input        rst,
    input        mode,
    input        run_stop,
    input        clear,
    output [7:0] msec,
    output [7:0] sec,
    output [7:0] min,
    output [7:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // 내부 카운터 출력용 wire 선언
    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;

    assign msec = {1'b0, w_msec};
    assign sec  = {2'b0, w_sec};
    assign min  = {2'b0, w_min};
    assign hour = {3'b0, w_hour};

    // hour
    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24)
    ) hour_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_hour_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(1'b0),
        .o_count       (hour),
        .o_tick        ()
    );

    // min
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_min_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(1'b0),
        .o_count       (min),
        .o_tick        (w_hour_tick)
    );

    // sec
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_sec_tick),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(1'b0),
        .o_count       (sec),
        .o_tick        (w_min_tick)
    );

    // msec
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk           (clk),
        .rst           (rst),
        .i_tick        (w_tick_100hz),
        .mode          (mode),
        .run_stop      (run_stop),
        .clear         (clear),
        .i_setting_tick(1'b0),
        .o_count       (msec),
        .o_tick        (w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .rst         (rst),
        .i_run_stop  (run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

// msec, sec, min, hour 
// tick counter
module tick_counter #(
    parameter BIT_WIDTH = 7,
    TIMES = 100,
    INIT_VAL = 0
) (
    input                      clk,
    input                      rst,
    input                      i_tick,
    input                      mode,
    input                      run_stop,
    input                      clear,
    input                      i_setting_tick,
    output     [BIT_WIDTH-1:0] o_count,
    output reg                 o_tick
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // state reg SL
    always @(posedge clk, posedge rst) begin
        if (rst | clear) begin
            counter_reg <= INIT_VAL;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if ((i_tick & run_stop) || i_setting_tick) begin
            if (mode == 1'b1) begin
                // down
                if (counter_reg == 0) begin
                    counter_next = TIMES - 1;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg - 1;
                    o_tick = 1'b0;
                end
            end else begin
                // up
                if (counter_reg == (TIMES - 1)) begin
                    counter_next = 0;
                    o_tick = 1'b1;
                end else begin
                    counter_next = counter_reg + 1;
                    o_tick = 1'b0;
                end
            end
        end
    end

endmodule

module mux_2x1_watch_stopwatch (
    input         sel,
    input  [31:0] i_sel0,
    input  [31:0] i_sel1,
    output [31:0] o_mux
);

    assign o_mux = (sel) ? i_sel1 : i_sel0; // true -> watch , false -> stopwatch

endmodule

module tick_gen_100hz (
    input      clk,
    input      rst,
    input      i_run_stop,
    output reg o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;

    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter    <= 0;
            o_tick_100hz <= 1'b0;
        end else begin
            if (i_run_stop) begin
                r_counter    <= r_counter + 1;
                o_tick_100hz <= 1'b0;
                if (r_counter == (F_COUNT - 1)) begin
                    r_counter    <= 0;
                    o_tick_100hz <= 1'b1;
                end else begin
                    o_tick_100hz <= 1'b0;
                end
            end
        end
    end

endmodule
