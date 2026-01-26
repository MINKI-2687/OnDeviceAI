`timescale 1ns / 1ps

module tb_top_adder ();
    reg        clk;
    reg        reset;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    top_10000_counter dut (
        .clk      (clk),
        .reset    (reset),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    // generate clock
    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        reset = 1;
        #10;
        reset = 0;
        #20000;
        $stop;
    end
endmodule
