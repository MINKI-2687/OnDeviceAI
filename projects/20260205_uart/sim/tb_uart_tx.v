`timescale 1ns / 1ps

module tb_uart_tx ();

    parameter BAUD = 9600;
    parameter BIT_PERIOD = 100_000_000 / BAUD * 10;  // 104_160ns
    parameter TICK_PERIOD = BIT_PERIOD / 16;  // 6.51us

    reg        clk;
    reg        rst;
    reg        tx_start;
    reg        b_tick;
    reg  [7:0] tx_data;
    wire       tx_busy;
    wire       tx_done;
    wire       uart_tx;

    uart_tx dut (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),
        .b_tick  (b_tick),
        .tx_data (tx_data),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        .uart_tx (uart_tx)
    );

    always #5 clk = ~clk;

    // b_tick을 1클록 폭의 펄스로 생성
    initial begin
        b_tick = 0;
        forever begin
            #(TICK_PERIOD); // 6.51us
            b_tick = 1;
            #10;
            b_tick = 0;
        end
    end

    initial begin
        #0;
        clk = 0;
        rst = 1;
        tx_start = 0;
        tx_data = 8'h41;
        #20;
        rst = 0;
        #20;
        tx_start = 1;
        #10;
        tx_start = 0;

        repeat (11) #(BIT_PERIOD);  // 104.16us

        #1000;
        $stop;
    end
endmodule
