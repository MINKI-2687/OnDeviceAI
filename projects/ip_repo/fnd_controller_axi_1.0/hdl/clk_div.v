module clk_div (
    input      clk,
    input      reset,
    output reg o_1khz
);

    //reg [16:0] counter_r;
    reg [$clog2(100_000)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_1khz    <= 1'b0;
        end else begin
            if (counter_r == 99999) begin
                counter_r <= 0;
                o_1khz    <= 1'b1;
            end else begin
                counter_r <= counter_r + 1;
                o_1khz    <= 1'b0;
            end
        end
    end
endmodule