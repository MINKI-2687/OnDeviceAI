`timescale 1ns / 1ps

module tb_tick_trigger ();

    reg clk, rst;
    wire trigger_tick;

    tick_trigger dut (
        .clk         (clk),
        .rst         (rst),
        .trigger_tick(trigger_tick)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        #10;
        rst = 0;

        repeat (10) @(posedge clk);
        $stop;
    end
endmodule
