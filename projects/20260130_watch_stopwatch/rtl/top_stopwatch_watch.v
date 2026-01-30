`timescale 1ns / 1ps

module top_stopwatch_watch (
    input clk,
    input reset,
    input [2:0] sw,  // sw[0] up/down // sw[1] watch select // sw[2] sel display
    input btn_r,  // i_run_stop     
    input btn_l,  // i_clear
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    //wire [13:0] w_counter;
    wire w_mode, w_run_stop, w_clear;
    wire o_btn_run_stop, o_btn_clear;
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

    control_unit U_CONTROL_UNIT (
        .clk       (clk),
        .reset     (reset),
        .i_mode    (sw[0]),
        .i_run_stop(o_btn_run_stop),
        .i_clear   (o_btn_clear),
        .o_mode    (w_mode),
        .o_run_stop(w_run_stop),
        .o_clear   (w_clear)
    );

    watch_datapath U_WATCH_DATAPATH (
        .clk(clk),
        .reset(reset),
        .mode(w_mode),
        .run_stop(1'b1),
        .clear(w_clear),
        .msec(w_watch_time[6:0]),
        .sec(w_watch_time[12:7]),
        .min(w_watch_time[18:13]),
        .hour(w_watch_time[23:19])
    );

    stopwatch_datapath U_STOPWATCH_DATAPATH (
        .clk     (clk),
        .reset   (reset),
        .mode    (w_mode),
        .run_stop(w_run_stop),
        .clear   (w_clear),
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

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .sel_display(sw[2]),
        .fnd_in_data(w_o_mux),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module watch_datapath (
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
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_hour_tick),
        .mode    (mode),
        .run_stop(1'b1),
        .clear   (clear),
        .o_count (hour),
        .o_tick  ()
    );

    // min
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_min_tick),
        .mode    (mode),
        .run_stop(1'b1),
        .clear   (clear),
        .o_count (min),
        .o_tick  (w_hour_tick)
    );

    // sec
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_sec_tick),
        .mode    (mode),
        .run_stop(1'b1),
        .clear   (clear),
        .o_count (sec),
        .o_tick  (w_min_tick)
    );

    // msec
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_tick_100hz),
        .mode    (mode),
        .run_stop(1'b1),
        .clear   (clear),
        .o_count (msec),
        .o_tick  (w_sec_tick)
    );

    tick_gen_100hz U_TICK_GEN (
        .clk         (clk),
        .reset       (reset),
        .i_run_stop  (1'b1),
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
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_hour_tick),
        .mode    (mode),
        .run_stop(run_stop),
        .clear   (clear),
        .o_count (hour),
        .o_tick  ()
    );

    // min
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) min_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_min_tick),
        .mode    (mode),
        .run_stop(run_stop),
        .clear   (clear),
        .o_count (min),
        .o_tick  (w_hour_tick)
    );

    // sec
    tick_counter #(
        .BIT_WIDTH(6),
        .TIMES    (60)
    ) sec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_sec_tick),
        .mode    (mode),
        .run_stop(run_stop),
        .clear   (clear),
        .o_count (sec),
        .o_tick  (w_min_tick)
    );

    // msec
    tick_counter #(
        .BIT_WIDTH(7),
        .TIMES    (100)
    ) msec_counter (
        .clk     (clk),
        .reset   (reset),
        .i_tick  (w_tick_100hz),
        .mode    (mode),
        .run_stop(run_stop),
        .clear   (clear),
        .o_count (msec),
        .o_tick  (w_sec_tick)
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
    TIMES = 100
) (
    input                      clk,
    input                      reset,
    input                      i_tick,
    input                      mode,
    input                      run_stop,
    input                      clear,
    output     [BIT_WIDTH-1:0] o_count,
    output reg                 o_tick
);

    // counter reg
    reg [BIT_WIDTH-1:0] counter_reg, counter_next;

    assign o_count = counter_reg;

    // state reg SL
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            counter_reg <= 0;
        end else begin
            counter_reg <= counter_next;
        end
    end

    // next CL
    always @(*) begin
        counter_next = counter_reg;
        o_tick = 1'b0;
        if (i_tick & run_stop) begin
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
