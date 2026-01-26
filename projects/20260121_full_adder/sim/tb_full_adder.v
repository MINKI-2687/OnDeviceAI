`timescale 1ns / 1ps

module tb_full_adder ();

    // tb_full_adder local variable
    reg a, b, cin;
    wire sum, carry;

    // instanciate half adder
    // half_adder dut (
    //     .a(a),
    //     .b(b),
    //     .sum(sum),
    //     .carry(carry)
    // );

    // instanciate full adder
    full_adder dut (
        .a  (a),
        .b  (b),
        .cin(cin),
        .sum(sum),
        .c  (carry)
    );

    initial begin
        #0;
        a   = 0;
        b   = 0;
        cin = 0;
        #10;
        a   = 1;
        b   = 0;
        cin = 0;
        #10;
        a   = 0;
        b   = 1;
        cin = 0;
        #10;
        a   = 1;
        b   = 1;
        cin = 0;
        #10;
        a   = 0;
        b   = 0;
        cin = 1;
        #10;
        a   = 1;
        b   = 0;
        cin = 1;
        #10;
        a   = 0;
        b   = 1;
        cin = 1;
        #10;
        a   = 1;
        b   = 1;
        cin = 1;
        #10;
        $stop;
        #100;
        $finish;
    end
endmodule
