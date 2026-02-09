`timescale 1ns / 1ps

module tb_btn_debounce ();

    reg clk, rst, i_btn;
    wire o_btn;

    btn_debounce dut (
        .clk  (clk),
        .reset(rst),
        .i_btn(i_btn),
        .o_btn(o_btn)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        rst   = 1;
        i_btn = 0;
        #10;
        rst = 0;
        #10;
        i_btn = 1;
        #100_000;
        i_btn = 0;
        #100_000;
        $stop;

    end
endmodule
