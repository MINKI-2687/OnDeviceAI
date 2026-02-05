`timescale 1ns / 1ps

module top_stopwatch_watch (
    input         clk,
    input         reset,
    // sw[0] up/down // sw[1] watch select // sw[2] sel display // sw[3] watch setting
    // sw[15:12] 자릿수 선택 스위치
    input  [15:0] sw,
    input         btn_r,      // i_run_stop     
    input         btn_l,      // i_clear
    input         btn_u,      // watch up setting
    input         btn_d,      // watch down setting
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data
);

    // btn
    wire o_btn_run_stop, o_btn_clear, o_btn_up, o_btn_down;

    // demux
    wire w_watch_up, w_watch_down, w_watch_run, w_watch_clear;
    wire w_sw_run, w_sw_clear;

    // control watch
    wire w_ctrl_watch_mode, w_ctrl_watch_run_stop, w_ctrl_watch_clear;
    wire w_h_digit, w_m_digit, w_s_digit, w_ms_digit;

    // control stopwatch
    wire w_ctrl_sw_run_stop, w_ctrl_sw_clear;

    wire [23:0] w_stopwatch_time;
    wire [23:0] w_watch_time;
    wire [23:0] w_o_mux;


    btn_debounce U_BD_RUNSTOP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_r),
        .o_btn(o_btn_run_stop)
    );

    btn_debounce U_BD_CLEAR (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_l),
        .o_btn(o_btn_clear)
    );

    btn_debounce U_BD_UP (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_u),
        .o_btn(o_btn_up)
    );

    btn_debounce U_BD_DOWN (
        .clk  (clk),
        .reset(reset),
        .i_btn(btn_d),
        .o_btn(o_btn_down)
    );

    sw_demux U_SW_DEMUX (
        .sel    (sw[1]),           // choice watch or stopwatch
        .i_btn_r(o_btn_run_stop),  // run_stop
        .i_btn_l(o_btn_clear),     // clear
        .i_btn_u(o_btn_up),        // up
        .i_btn_d(o_btn_down),      // down

        // setting mode
        .o_watch_run  (w_watch_run),
        .o_watch_clear(w_watch_clear),
        .o_watch_up   (w_watch_up),
        .o_watch_down (w_watch_down),

        .o_sw_run_stop(w_sw_run),
        .o_sw_clear   (w_sw_clear)
    );

    watch_control_unit U_WATCH_CONTROL_UNIT (
        .clk         (clk),
        .reset       (reset),
        .i_setting   (sw[3]),
        .i_digit_sel (sw[15:12]),
        .i_btn_up    (w_watch_up),             // up setting
        .i_btn_down  (w_watch_down),           // down setting
        .i_mode      (sw[0]),
        .i_run       (w_watch_run),
        .i_clear     (w_watch_clear),
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
        .reset     (reset),
        .i_mode    (sw[0]),
        .i_run_stop(w_sw_run),
        .i_clear   (w_sw_clear),
        .o_mode    (w_ctrl_sw_mode),
        .o_run_stop(w_ctrl_sw_run_stop),
        .o_clear   (w_ctrl_sw_clear)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_ctrl_watch_mode),
        .run_stop(w_ctrl_watch_run_stop),
        .clear   (w_ctrl_watch_clear),
        .h_digit (w_h_digit),
        .m_digit (w_m_digit),
        .s_digit (w_s_digit),
        .ms_digit(w_ms_digit),
        .msec    (w_watch_time[6:0]),
        .sec     (w_watch_time[12:7]),
        .min     (w_watch_time[18:13]),
        .hour    (w_watch_time[23:19])
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_ctrl_sw_mode),
        .run_stop(w_ctrl_sw_run_stop),
        .clear   (w_ctrl_sw_clear),
        .msec    (w_stopwatch_time[6:0]),    // 7bit
        .sec     (w_stopwatch_time[12:7]),   // 6bit
        .min     (w_stopwatch_time[18:13]),  // 6bit
        .hour    (w_stopwatch_time[23:19])   // 5bit
    );

    mux_2x1_watch_stopwatch U_MUX_MODE_SELCET (
        .sel   (sw[1]),
        .i_sel0(w_stopwatch_time),
        .i_sel1(w_watch_time),
        .o_mux (w_o_mux)
    );

    //assign w_o_mux = (sw[1]) ? w_watch_time : w_stopwatch_time;

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_o_mux),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module sw_demux (
    input sel,  // choice watch or stopwatch
    input i_btn_r,  // run_stop
    input i_btn_l,  // clear
    input i_btn_u,  // up
    input i_btn_d,  // down

    output o_watch_run,
    output o_watch_clear,
    // setting mode
    output o_watch_up,
    output o_watch_down,

    output o_sw_run_stop,
    output o_sw_clear
);

    // 시계 모드(sel=1): 상/하 버튼을 설정용으로 보냄, sw[1]
    assign o_watch_run   = (sel) ? i_btn_r : 1'b0;
    assign o_watch_clear = (sel) ? i_btn_l : 1'b0;
    assign o_watch_up    = (sel) ? i_btn_u : 1'b0;
    assign o_watch_down  = (sel) ? i_btn_d : 1'b0;

    // 스톱워치 모드(sel=0): 오른쪽 버튼을 실행/정지용으로 보냄, sw[1]
    assign o_sw_run_stop = (!sel) ? i_btn_r : 1'b0;
    assign o_sw_clear    = (!sel) ? i_btn_l : 1'b0;

endmodule

module watch_datapath (
    input        clk,
    input        reset,
    input        mode,
    input        run_stop,
    input        clear,
    input        h_digit,
    input        m_digit,
    input        s_digit,
    input        ms_digit,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // hour
    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24),
        .INIT_VAL (12)
    ) hour_counter (
        .clk           (clk),
        .reset         (reset),
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
        .reset         (reset),
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
        .reset         (reset),
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
        .reset         (reset),
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
        .reset       (reset),
        .i_run_stop  (run_stop),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

module stopwatch_datapath (
    input        clk,
    input        reset,
    input        mode,
    input        run_stop,
    input        clear,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    // hour
    tick_counter #(
        .BIT_WIDTH(5),
        .TIMES    (24)
    ) hour_counter (
        .clk           (clk),
        .reset         (reset),
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
        .reset         (reset),
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
        .reset         (reset),
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
        .reset         (reset),
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
        .reset       (reset),
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
    input                      reset,
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
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
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
    input  [23:0] i_sel0,
    input  [23:0] i_sel1,
    output [23:0] o_mux
);

    assign o_mux = (sel) ? i_sel1 : i_sel0; // true -> watch , false -> stopwatch

endmodule

module tick_gen_100hz (
    input      clk,
    input      reset,
    input      i_run_stop,
    output reg o_tick_100hz
);
    parameter F_COUNT = 100_000_000 / 100;

    reg [$clog2(F_COUNT)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
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
