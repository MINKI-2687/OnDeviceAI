`timescale 1ns / 1ps

module fnd_controller (
    input         clk,
    input         rst,
    input  [15:0] fnd_in_data,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data
);
    wire [3:0] w_distance_digit_1;
    wire [3:0] w_distance_digit_10;
    wire [3:0] w_distance_digit_100;
    wire [3:0] w_distance_digit_1000;

    wire [3:0] w_mux_4x1_out;
    wire [1:0] w_digit_sel;
    wire w_1khz;

    digit_splitter #(
        .BIT_WIDTH(24)
    ) U_DIST_DS (
        .in_data   (fnd_in_data),
        .digit_1   (w_distance_digit_1),
        .digit_10  (w_distance_digit_10),
        .digit_100 (w_distance_digit_100),
        .digit_1000(w_distance_digit_1000)
    );

    mux4x1 U_MUX_4x1 (
        .sel       (w_digit_sel),
        .digit_1   (w_distance_digit_1),
        .digit_10  (w_distance_digit_10),
        .digit_100 (w_distance_digit_100),
        .digit_1000(w_distance_digit_1000),
        .mux_out   (w_mux_4x1_out)
    );

    clk_div U_CLK_DIV (
        .clk   (clk),
        .rst   (rst),
        .o_1khz(w_1khz)
    );

    counter_4 U_COUNTER_4 (
        .clk      (clk),
        .rst      (rst),
        .w_1khz   (w_1khz),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DECODER_2x4 (
        .digit_sel  (w_digit_sel),
        .decoder_out(fnd_digit)
    );

    bcd U_BCD (
        .bcd     (w_mux_4x1_out),
        .fnd_data(fnd_data)
    );

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

module counter_4 (
    input        clk,
    input        rst,
    input        w_1khz,
    output [1:0] digit_sel
);

    reg [1:0] counter_r;

    assign digit_sel = counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;  // init counter_r
        end else begin
            if (w_1khz)
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

module mux4x1 (
    input      [1:0] sel,
    input      [3:0] digit_1,
    input      [3:0] digit_10,
    input      [3:0] digit_100,
    input      [3:0] digit_1000,
    output reg [3:0] mux_out
);

    always @(*) begin
        case (sel)
            2'b00:   mux_out = digit_1;
            2'b01:   mux_out = digit_10;
            2'b10:   mux_out = digit_100;
            2'b11:   mux_out = digit_1000;
            default: mux_out = 4'd0;
        endcase
    end

endmodule

module digit_splitter #(
    parameter BIT_WIDTH = 24
) (
    input  [BIT_WIDTH-1:0] in_data,
    output [          3:0] digit_1,
    output [          3:0] digit_10,
    output [          3:0] digit_100,
    output [          3:0] digit_1000
);

    // 온도 데이터 (하위 8비트)
    wire [7:0] temp_val = in_data[7:0];
    // 습도 데이터 (상위 8비트)
    wire [7:0] hum_val = in_data[15:8];

    // 온도 쪼개기
    assign digit_1    = temp_val % 10;
    assign digit_10   = (temp_val / 10) % 10;

    // 습도 쪼개기
    assign digit_100  = hum_val % 10;
    assign digit_1000 = (hum_val / 10) % 10;

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
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule
