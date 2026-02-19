`timescale 1ns / 1ps

module fnd_controller (
    input         clk,
    input         rst,
    input         sel_display,  // sw[2]
    input         dot,
    input  [31:0] fnd_in_data,  // system_top
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data
);

    // 내부 연결용 와이어
    wire [15:0] w_sel_data;
    wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    wire [2:0] w_digit_sel;  // counter_8의 출력 (0~7)
    wire [3:0] w_mux_out;
    wire       w_1khz;

    wire       w_dot_onoff;
    wire [3:0] w_dot_value = (dot & w_dot_onoff) ? 4'he : 4'hf;

    assign w_sel_data = (sel_display) ? fnd_in_data[31:16] : fnd_in_data[15:0];

    // 하위 8비트 (오른쪽 2자리)
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DS_LOW (
        .in_data (w_sel_data[7:0]),
        .digit_1 (w_digit_1),
        .digit_10(w_digit_10)
    );

    // 상위 8비트 (왼쪽 2자리)
    digit_splitter #(
        .BIT_WIDTH(8)
    ) U_DS_HIGH (
        .in_data (w_sel_data[15:8]),
        .digit_1 (w_digit_100),
        .digit_10(w_digit_1000)
    );

    counter_8 U_COUNTER_8 (
        .clk      (w_1khz),
        .rst      (rst),
        .digit_sel(w_digit_sel)  // 3비트 출력 
    );

    mux_8x1 U_MUX_8x1 (
        .sel           (w_digit_sel),
        .digit_1       (w_digit_1),
        .digit_10      (w_digit_10),
        .digit_100     (w_digit_100),
        .digit_1000    (w_digit_1000),
        .digit_dot_1   (4'hf),
        .digit_dot_10  (4'hf),
        .digit_dot_100 (w_dot_value),   // '.'
        .digit_dot_1000(4'hf),
        .mux_out       (w_mux_out)
    );

    dot_onoff_comp U_DOT_ONOFF (
        .msec     (fnd_in_data[6:0]),
        .dot_onoff(w_dot_onoff)
    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    decoder_2x4 U_DECODER (
        .digit_sel  (w_digit_sel[1:0]), // 하위 2비트만 사용해서 4자리 선택
        .decoder_out(fnd_digit)
    );

    bcd U_BCD (
        .bcd     (w_mux_out),
        .fnd_data(fnd_data)
    );

endmodule

module dot_onoff_comp (
    input [6:0] msec,
    output dot_onoff
);

    assign dot_onoff = (msec < 50);  // true -> 1 , false -> 0

endmodule

module clk_div (
    input      clk,
    input      rst,
    output reg o_1khz
);

    //reg [16:0] counter_r;
    reg [$clog2(100_000)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
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

module counter_8 (
    input        clk,
    input        rst,
    output [2:0] digit_sel
);

    reg [2:0] counter_r;

    assign digit_sel = counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;  // init counter_r
        end else begin
            // to do
            counter_r <= counter_r + 1;
        end
    end
endmodule

module decoder_2x4 (
    input      [1:0] digit_sel,
    output reg [3:0] decoder_out
);

    always @(digit_sel) begin
        case (digit_sel)
            2'b00:   decoder_out = 4'b1110;
            2'b01:   decoder_out = 4'b1101;
            2'b10:   decoder_out = 4'b1011;
            2'b11:   decoder_out = 4'b0111;
            default: decoder_out = 4'b1111;
        endcase
    end
endmodule

module mux_8x1 (
    input      [2:0] sel,
    input      [3:0] digit_1,
    input      [3:0] digit_10,
    input      [3:0] digit_100,
    input      [3:0] digit_1000,
    input      [3:0] digit_dot_1,
    input      [3:0] digit_dot_10,
    input      [3:0] digit_dot_100,
    input      [3:0] digit_dot_1000,
    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            3'b000:  mux_out = digit_1;
            3'b001:  mux_out = digit_10;
            3'b010:  mux_out = digit_100;
            3'b011:  mux_out = digit_1000;
            3'b100:  mux_out = digit_dot_1;
            3'b101:  mux_out = digit_dot_10;
            3'b110:  mux_out = digit_dot_100;
            3'b111:  mux_out = digit_dot_1000;
            default: mux_out = 4'hF;
        endcase
    end
endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 7
) (
    input [BIT_WIDTH-1:0] in_data,
    output [3:0] digit_1,
    output [3:0] digit_10
);

    assign digit_1  = in_data % 10;
    assign digit_10 = (in_data / 10) % 10;

endmodule

module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data  // always output must reg type
);

    always @(bcd) begin
        case (bcd)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            4'd10: fnd_data = 8'hff;
            4'd11: fnd_data = 8'hff;
            4'd12: fnd_data = 8'hff;
            4'd13: fnd_data = 8'hff;
            4'd14: fnd_data = 8'h7f;
            4'd15: fnd_data = 8'hff;
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule
