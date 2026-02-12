`timescale 1ns / 1ps

module tb_uart_to_decoder ();
    reg clk, rst;
    reg rx, b_tick;
    wire uart_btn_r;
    wire uart_btn_l;
    wire uart_btn_u;
    wire uart_btn_d;
    wire uart_sw_mode;
    wire uart_sw_sel_mode;
    wire uart_sw_sel_display;

    wire [7:0] rx_data;
    wire rx_done;

    uart_rx dut_uart (
        .clk    (clk),
        .rst    (rst),
        .rx     (rx),
        .b_tick (b_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    ascii_decoder dut_decoder (
        .clk                (clk),
        .rst                (rst),
        .rx_data            (rx_data),
        .rx_done            (rx_done),
        // from uart input (r, l, u, d)
        .uart_btn_r         (uart_btn_r),          // run_stop
        .uart_btn_l         (uart_btn_l),          // clear
        .uart_btn_u         (uart_btn_u),          // up
        .uart_btn_d         (uart_btn_d),          // down
        // from uart input (sw[0], [1], [2])
        .uart_sw_mode       (uart_sw_mode),
        .uart_sw_sel_mode   (uart_sw_sel_mode),
        .uart_sw_sel_display(uart_sw_sel_display)
    );

    always #5 clk = ~clk;

    initial begin
        b_tick = 0;
        forever begin
            #6510;  // TICK_PERIOD
            b_tick = 1;
            #10;
            b_tick = 0;
        end
    end

    task send_uart_serial(input [7:0] data);
        integer i;
        begin
            rx = 0;
            #104160;  // Start Bit
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #104160;  // Data Bits
            end
            rx = 1;
            #104160;  // Stop Bit
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        b_tick = 0;
        rx = 1;  // IDLE 상태는 반드시 1
        #20 rst = 0;

        #100;
        send_uart_serial(8'h72);  // 'r' 키를 시리얼로 전송
    end
endmodule
