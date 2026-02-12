`timescale 1ns / 1ps

module tb_uart_loop_back ();

    // 
    parameter BAUD = 9600;
    parameter BUAD_PERIOD = (100_000_000 / BAUD) * 10;  // 104_160

    reg        clk;
    reg        rst;
    reg        uart_rx;
    wire       uart_tx;
    wire [7:0] rx_data;
    wire       rx_done;

    reg  [7:0] test_data;
    integer i = 0, j = 0;

    uart_top DUT (
        .clk    (clk),
        .rst    (rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    always #5 clk = ~clk;

    task uart_sender();
        begin
            //uart test pattern 
            //start
            uart_rx = 0;
            #(BUAD_PERIOD);
            //data 
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = test_data[i];
                #(BUAD_PERIOD);
            end
            //stop
            uart_rx = 1'b1;
            #(BUAD_PERIOD);

        end

    endtask

    initial begin
        #0;
        clk       = 0;
        rst       = 1;
        uart_rx   = 1'b1;
        test_data = 8'h31;  // ascii '1' 
        // 
        repeat (5) @(posedge clk);
        rst = 1'b0;

        for (j = 0; j < 10; j = j + 1) begin
            test_data = 8'h30 + j;
            uart_sender();
            #(BUAD_PERIOD);
        end

        // hold uart tx output 
        for (j = 0; j < 12; j = j + 1) begin
            #(BUAD_PERIOD);
        end
        $stop;
    end

endmodule
