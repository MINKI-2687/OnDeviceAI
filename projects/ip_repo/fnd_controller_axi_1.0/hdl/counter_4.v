module counter_4 (
    input        clk,
    input        reset,
    output [1:0] digit_sel
);

    reg [1:0] counter_r;

    assign digit_sel = counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;  // init counter_r
        end else begin
            // to do
            counter_r <= counter_r + 1;
        end
    end
endmodule