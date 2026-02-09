`timescale 1ns / 1ps

module tb_baud_tick ();

    reg clk, rst;
    wire b_tick;

    baud_tick dut (
        .clk   (clk),
        .rst   (rst),
        .b_tick(b_tick)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        #10;
        rst = 0;
        #100_000;

        $stop;
    end
endmodule
