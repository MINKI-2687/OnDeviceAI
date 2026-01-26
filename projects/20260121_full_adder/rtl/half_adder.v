module half_adder (
    input  a,
    input  b,
    output sum,
    output carry
);
    // half adder
    assign sum   = a ^ b;
    assign carry = a & b;

endmodule
