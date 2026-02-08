`timescale 1ns / 1ps

module sw_watch_data (
    input         clk,
    input         reset,
    // watch control
    input         w_mode,
    input         w_run_stop,
    input         w_clear,
    input         w_h_digit,
    input         w_m_digit,
    input         w_s_digit,
    input         w_ms_digit,
    // stopwatch control
    input         sw_mode,
    input         sw_run_stop,
    input         sw_clear,
    // stopwatch, watch mode select
    input         sel_mode,
    // output
    output [23:0] time_data
);

    wire [23:0] w_watch_time;
    wire [23:0] w_stopwatch_time;

    watch_datapath U_WATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .run_stop(w_run_stop),
        .clear   (w_clear),
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
        .mode    (sw_mode),
        .run_stop(sw_run_stop),
        .clear   (sw_clear),
        .msec    (w_stopwatch_time[6:0]),    // 7bit
        .sec     (w_stopwatch_time[12:7]),   // 6bit
        .min     (w_stopwatch_time[18:13]),  // 6bit
        .hour    (w_stopwatch_time[23:19])   // 5bit
    );

    mux_2x1_watch_stopwatch U_MUX_MODE_SELCET (
        .sel   (sel_mode),
        .i_sel0(w_stopwatch_time),
        .i_sel1(w_watch_time),
        .o_mux (time_data)
    );

    //assign time_data = (sel_mode) ? w_watch_time : w_stopwatch_time;

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
