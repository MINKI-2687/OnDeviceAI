`timescale 1ns / 1ps

// top module
module gates(
    // input
    input  a,
    input  b,
    // output
    output y0,
    output y1,
    output y2,
    output y3,
    output y4,
    output y5,
    output y6
    );

    // AND
    assign y0 = a & b;
    // NAND
    assign y1 = ~(a & b);
    // OR
    assign y2 = a | b;
    // NOR
    assign y3 = ~(a | b);
    // XOR
    assign y4 = a ^ b;
    // XNOR
    assign y5 = ~(a ^ b);
    // NOT
    assign y6 = ~a;

endmodule
