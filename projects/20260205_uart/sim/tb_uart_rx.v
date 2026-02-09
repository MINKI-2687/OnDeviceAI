`timescale 1ns / 1ps

module tb_uart_rx ();

    parameter BAUD = 9600;
    parameter BIT_PERIOD = 100_000_000 / BAUD * 10;  // 104_160ns
    parameter TICK_PERIOD = BIT_PERIOD / 16;  // 6.51us

    reg clk, rst, rx, b_tick;
    wire [7:0] rx_data;
    wire rx_done;

    uart_rx dut (
        .clk    (clk),
        .rst    (rst),
        .rx     (rx),
        .b_tick (b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    always #5 clk = ~clk;

    // b_tick을 1클록 폭의 펄스로 생성
    initial begin
        b_tick = 0;
        forever begin
            #(TICK_PERIOD);
            b_tick = 1;
            #10;
            b_tick = 0;
        end
    end

    initial begin
        #0;
        clk = 0;
        rst = 1;
        rx  = 1;
        #20;
        rst = 0;

        // Start Bit (0)
        rx  = 0; #(BIT_PERIOD);

        // 'A' (8'h41) -> LSB 우선 전송: 1, 0, 0, 0, 0, 0, 1, 0
        rx = 1; #(BIT_PERIOD);  // bit 0 (1)
        rx = 0; #(BIT_PERIOD);  // bit 1 (0)
        rx = 0; #(BIT_PERIOD);  // bit 2 (0)
        rx = 0; #(BIT_PERIOD);  // bit 3 (0)
        rx = 0; #(BIT_PERIOD);  // bit 4 (0)
        rx = 0; #(BIT_PERIOD);  // bit 5 (0)
        rx = 1; #(BIT_PERIOD);  // bit 6 (1)
        rx = 0; #(BIT_PERIOD);  // bit 7 (0)

        // Stop Bit (1)
        rx = 1;
        #(BIT_PERIOD);

        #1000;
        $stop;
    end
endmodule
