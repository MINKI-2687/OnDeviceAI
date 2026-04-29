module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] decoder_out
);

    always @(digit_sel) begin
        case (digit_sel)
            2'b00: decoder_out = 4'b1110;
            2'b01: decoder_out = 4'b1101;
            2'b10: decoder_out = 4'b1011;
            2'b11: decoder_out = 4'b0111;
        endcase
    end
endmodule