`timescale 1ns / 1ps

module tb_rv32i ();

    logic clk, rst;
    logic [ 7:0] gpi;
    wire  [ 7:0] gpo;
    wire  [15:0] gpio;
    wire  [ 3:0] fnd_digit;
    wire  [ 7:0] fnd_data;
    logic        uart_rx;
    wire         uart_tx;

    rv32i_mcu dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        gpi = 8'h00;
        @(negedge clk);
        @(negedge clk);
        rst = 0;

        gpi = 8'haa;
        repeat (1100) @(negedge clk);
        repeat (1100) @(negedge clk);
        $stop;
    end
endmodule
