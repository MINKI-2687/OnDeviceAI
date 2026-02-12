`timescale 1ns / 1ps

module tb_controller_SR04 ();
    reg         clk;
    reg         rst;
    reg         btn_r;
    reg         i_tick_1us;
    reg         echo;
    wire        o_trigger;
    wire [23:0] distance;

    controller_SR04 dut (
        .clk       (clk),
        .rst       (rst),
        .btn_r     (btn_r),
        .i_tick_1us(i_tick_1us),
        .echo      (echo),
        .o_trigger (o_trigger),
        .distance  (distance)
    );

    always #5 clk = ~clk;

    initial begin
        i_tick_1us = 0;
        forever begin
            #990;  // 990ns 대기
            @(posedge clk);
            i_tick_1us = 1;
            @(posedge clk);
            i_tick_1us = 0;
        end
    end

    initial begin
        clk        = 0;
        rst        = 1;
        btn_r      = 0;
        i_tick_1us = 0;
        echo       = 0;
        #20;
        rst = 0;

        #50;
        btn_r = 1;
        #10;
        btn_r = 0;

        #15_000;
        echo = 1;
        #580_000;
        echo = 0;

        #100_000;
        $stop;
    end
endmodule
