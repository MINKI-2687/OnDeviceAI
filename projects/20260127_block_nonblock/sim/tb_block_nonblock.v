`timescale 1ns / 1ps

module tb_block_nonblock ();

    reg a, b, c;

    initial begin
        #0;
        // blocking
        a = 1;
        b = 0;
        c = 0;
        #10;
        a = b;
        b = a;
        c = a + b;
        #10;

        // nonblocking (nb)
        a = 1;
        b = 0;
        c = 0;
        #10;
        a <= b;
        b <= a;
        c <= a + b;
        #10;
        $stop;
    end

endmodule
