`timescale 1ns / 1ps

module tb_top_10000_counter ();
    reg clk;
    reg reset;
    reg [2:0] sw;  // mode(0), run_stop(1), clear(2)
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    integer i = 0;

    top_10000_counter dut (
        .clk      (clk),
        .reset    (reset),
        .sw       (sw),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    // generate clock
    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        reset = 1;
        sw[0] = 0;
        sw[1] = 0;
        sw[2] = 0;
        #10;
        reset = 0;
        #10;
        sw[0] = 0;
        sw[1] = 1;
        sw[2] = 0;
        #10_000_000;
        sw[0] = 1;
        sw[1] = 1;
        sw[2] = 0;
        #20_000_000;
        sw[0] = 0;
        sw[1] = 1;
        sw[2] = 0;
        #20_000_000;
        sw[0] = 1;
        sw[1] = 0;
        sw[2] = 0;
        #2_000_000;
        sw[0] = 0;
        sw[1] = 1;
        sw[2] = 1;
        #2_000_000;
        sw[0] = 0;
        sw[1] = 1;
        sw[2] = 0;
        #1_000_000;
        sw[0] = 0;
        sw[1] = 1;
        sw[2] = 1;

        #200_000;
        $stop;
    end
endmodule
