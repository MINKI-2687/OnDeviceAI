`timescale 1ns / 1ps

module sensor_top (
    input         clk,
    input         rst,
    input  [15:0] sw,
    input         start,
    inout         dhtio,
    output [ 3:0] fnd_digit,
    output [ 7:0] fnd_data,
    //output [ 2:0] debug,
    //output        dht11_done,
    //output       dht11_valid
    output [15:0] led
);
    wire dht11_done;
    assign led[4] = (sw[3]) ? 1'b1 : 1'b0;
    wire dot = 1'b1;

    wire [15:0] w_humidity;
    wire [15:0] w_temperature;
    wire w_o_btn;

    btn_debounce U_BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(start),
        .o_btn(w_o_btn)
    );

    // DHT11
    dht11_controller U_DHT11 (
        .clk        (clk),
        .rst        (rst),
        .start      (w_o_btn),
        .humidity   (w_humidity),
        .temperature(w_temperature),
        .dht11_done (dht11_done),
        .dht11_valid(led[15]),
        .debug      (led[14:12]),
        .dhtio      (dhtio)
    );

    // FND
    fnd_controller U_FND (
        .clk        (clk),
        .rst        (rst),
        .dot        (dot),
        .fnd_in_data({w_humidity[15:8], w_temperature[15:8]}),
        .fnd_digit  (fnd_digit),
        .fnd_data   (fnd_data)
    );

endmodule
