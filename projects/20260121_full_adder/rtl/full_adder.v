`timescale 1ns / 1ps

module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output c
);

    wire w_ha_sum, w_ha0_c, w_ha1_c;
    assign c = w_ha0_c | w_ha1_c;  // to full adder output c

    half_adder U_HA0 (
        .a    (a),         // from full adder input a
        .b    (b),
        .sum  (w_ha_sum),
        .carry(w_ha0_c)
    );

    half_adder U_HA1 (
        .a    (w_ha_sum),  // from half adder0 output sum
        .b    (cin),
        .sum  (sum),       // to full adder output sum
        .carry(w_ha1_c)
    );

endmodule
