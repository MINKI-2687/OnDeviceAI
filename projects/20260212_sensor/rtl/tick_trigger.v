`timescale 1ns / 1ps

module tick_gen_1Mhz (
    input      clk,
    input      rst,
    output reg o_tick_1Mhz
);

    parameter SYS_CLK = 100_000_000;
    parameter TICK = 100_000_000 / 1_000_000;

    reg [$clog2(TICK)-1:0] r_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter   <= 0;
            o_tick_1Mhz <= 1'b0;
        end else begin
            if (r_counter == TICK - 1) begin
                r_counter <= 0;
                o_tick_1Mhz = 1'b1;
            end else begin
                r_counter   <= r_counter + 1;
                o_tick_1Mhz <= 1'b0;
            end
        end
    end

endmodule
