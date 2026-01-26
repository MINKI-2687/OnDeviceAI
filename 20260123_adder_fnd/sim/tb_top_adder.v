`timescale 1ns / 1ps

module tb_top_adder ();
    reg clk, reset;
    reg  [7:0] a;
    reg  [7:0] b;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;
    //wire       c;

    integer i = 0, j = 0;

    top_adder dut (
        .clk      (clk),
        .reset    (reset),
        .a        (a),
        .b        (b),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
        //.c        (c)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk   = 0;
        reset = 1;
        a     = 8'h00;
        b     = 8'h00;
        #20;
        reset = 0;
        for (i = 0; i < 256; i = i + 1) begin
            for (j = 0; j < 256; j = j + 1) begin
                a = i;
                b = j;
                #10;
            end
        end
        /*$stop;
        #1000;
        $finish;*/
    end
endmodule
