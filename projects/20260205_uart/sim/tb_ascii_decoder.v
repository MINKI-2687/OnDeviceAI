`timescale 1ns / 1ps

module tb_ascii_decoder ();
    reg        clk;
    reg        rst;
    reg  [7:0] rx_data;
    reg        rx_done;
    wire       uart_btn_r;
    wire       uart_btn_l;
    wire       uart_btn_u;
    wire       uart_btn_d;
    wire       uart_sw_mode;
    wire       uart_sw_sel_mode;
    wire       uart_sw_sel_display;


    ascii_decoder dut (
        .clk                (clk),
        .rst                (rst),
        .rx_data            (rx_data),
        .rx_done            (rx_done),
        .uart_btn_r         (uart_btn_r),
        .uart_btn_l         (uart_btn_l),
        .uart_btn_u         (uart_btn_u),
        .uart_btn_d         (uart_btn_d),
        .uart_sw_mode       (uart_sw_mode),
        .uart_sw_sel_mode   (uart_sw_sel_mode),
        .uart_sw_sel_display(uart_sw_sel_display)
    );

    always #5 clk = ~clk;

    // 데이터를 보내는 과정을 Task로 정의
    task send_char(input [7:0] char);
        begin
            @(posedge clk);
            rx_data = char;
            rx_done = 1;  // 데이터 도착
            @(posedge clk);
            rx_done = 0;
            repeat (2) @(posedge clk);
        end
    endtask

    initial begin
        #0;
        clk     = 0;
        rst     = 1;
        rx_done = 0;
        rx_data = 0;
        #20;
        rst = 0;

        // btn test
        send_char(8'h72);  // 'r' -> btn_r
        send_char(8'h6C);  // 'l' -> btn_l

        // switch test
        send_char(8'h30);  // '0' -> sw_mode Toggle (0->1)
        send_char(8'h30);  // '0' -> sw_mode Toggle (1->0)

        #100;
        $stop;
    end
endmodule
