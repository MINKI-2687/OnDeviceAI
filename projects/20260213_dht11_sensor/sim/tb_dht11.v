`timescale 1ns / 1ps

module tb_dht11 ();
    reg clk, rst;
    reg            start;
    reg            dht11_sensor_io;
    reg            sensor_io_sel;
    wire    [15:0] humidity;
    wire    [15:0] temperature;
    wire           dht11_done;
    wire           dht11_valid;
    wire    [ 2:0] debug;
    wire           dhtio;

    integer        i = 0;

    // sensor data
    reg     [39:0] dht11_sensor_data;

    assign dhtio = (sensor_io_sel) ? 1'bz : dht11_sensor_io;

    dht11_controller dut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .humidity   (humidity),
        .temperature(temperature),
        .dht11_done (dht11_done),
        .dht11_valid(dht11_valid),
        .debug      (debug),
        .dhtio      (dhtio)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk               = 0;
        rst               = 1;
        start             = 0;
        dht11_sensor_io   = 1'b0;
        sensor_io_sel     = 1'b1;
        // humidity integral, decimal, temperature integral, decimal, checksum
        dht11_sensor_data = {8'h32, 8'h00, 8'h19, 8'h00, 8'h4B};

        // reset
        #20;
        rst = 0;
        #20;
        start = 1;
        #10;
        start = 0;

        // 19msec + 30usec 뒤에 출력 끊어짐 MCU
        // start signal + wait
        #(1900 * 10 * 1000 + 40_000);

        // to output, sensor to FPGA
        sensor_io_sel   = 0;

        // sync_L, sync_H
        dht11_sensor_io = 1'b0;
        #(80_000);
        dht11_sensor_io = 1'b1;
        #(80_000);

        // 40bit data pattern
        for (i = 39; i >= 0; i = i - 1) begin
            // data_sync_l
            dht11_sensor_io = 1'b0;
            #(50_000);
            // data_value_h
            if (dht11_sensor_data[i] == 0) begin
                dht11_sensor_io = 1'b1;
                #(28_000);
            end else begin
                dht11_sensor_io = 1'b1;
                #(70_000);
            end
        end

        dht11_sensor_io = 1'b0;
        #(50_000);

        // to output, FPGA to sensor
        sensor_io_sel = 1;

        #100_000;


        #1000;
        $stop;
    end
endmodule
