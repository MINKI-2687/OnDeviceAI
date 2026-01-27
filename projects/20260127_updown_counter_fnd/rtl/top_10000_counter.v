`timescale 1ns / 1ps

module top_10000_counter (
    input        clk,
    input        reset,
    input  [2:0] sw,         // mode(0), run_stop(1), clear(2)
    output [3:0] fnd_digit,
    output [7:0] fnd_data
);

    wire [13:0] w_counter;
    wire w_tick_1khz;

    tick_gen_1khz U_TICK_GEN (
        .clk        (clk),
        .reset      (reset),
        .o_tick_1khz(w_tick_1khz)
    );

    counter_10000 U_COUNTER_10000 (
        .clk     (clk),
        .reset   (reset),
        .mode    (sw[0]),
        .run_stop(sw[1]),
        .clear   (sw[2]),
        .i_tick  (w_tick_1khz),
        .counter (w_counter)
    );

    fnd_controller U_FND_CNTL (
        .clk        (clk),
        .reset      (reset),
        .fnd_in_data(w_counter),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule

module tick_gen_1khz (
    input      clk,
    input      reset,
    output reg o_tick_1khz
);

    reg [$clog2(100_000)-1:0] r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter   <= 0;
            o_tick_1khz <= 1'b0;
        end else begin
            if (r_counter == (100_000 - 1)) begin
                r_counter   <= 0;
                o_tick_1khz <= 1'b1;
            end else begin
                r_counter   <= r_counter + 1;
                o_tick_1khz <= 1'b0;
            end
        end
    end

endmodule

module counter_10000 (
    input         clk,
    input         reset,
    input         i_tick,
    input         mode,
    input         run_stop,
    input         clear,
    output [13:0] counter
);

    reg [13:0] r_counter;

    assign counter = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            // reset, clear init
            r_counter <= 14'd0;
        end else begin
            if (run_stop) begin
                if (i_tick) begin  // all count have to operate (i_tick -> 1)
                    if (mode) begin
                        // down count
                        if (r_counter == 0) begin
                            r_counter <= 14'd9999;
                        end else begin
                            r_counter <= r_counter - 1;
                        end
                    end else begin
                        // up count
                        if (r_counter == 9999) begin
                            r_counter <= 14'd0;
                        end else begin
                            r_counter <= r_counter + 1;
                        end
                    end
                end
            end else begin
                r_counter <= r_counter;
            end
        end
    end

endmodule
