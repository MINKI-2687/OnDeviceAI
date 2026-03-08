`timescale 1ns / 1ps

module tb_cpu ();

    logic clk, rst;
    logic [7:0] out;

    general_reg_cpu dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        @(posedge clk);
        @(negedge clk);
        rst = 0;
        repeat (45) @(posedge clk);
        $stop;
    end
endmodule
