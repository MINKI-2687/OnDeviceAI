/*`timescale 1ns / 1ps

module tb_uart_tx ();

    parameter BAUD_9600 = 104_160;

    reg clk, rst, btn_down;  // need to btn_down 100msec
    wire uart_tx;

    uart_top dut (
        .clk     (clk),
        .rst     (rst),
        .btn_down(btn_down),
        .uart_tx (uart_tx)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        btn_down = 0;
        #20;
        // reset
        rst = 0;

        // btn down, tx start
        btn_down = 1'b1;
        #100_000;  // 100usec
        btn_down = 1'b0;

        #(BAUD_9600 * 16);

        $stop;
    end

endmodule*/

`timescale 1ns / 1ps

module tb_system_top;

    // 1. DUT Signals
    reg clk;
    reg rst;
    reg [15:0] sw;
    reg btn_r, btn_l, btn_u, btn_d;
    reg uart_rx;

    wire uart_tx;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;
    wire [15:0] led;

    // 2. Parameters for UART Simulation
    // 9600 baud rate -> 1 bit duration = 1/9600 sec = approx 104,167 ns
    parameter BIT_PERIOD = 104167; 

    // 3. DUT Instantiation
    system_top DUT (
        .clk      (clk),
        .rst      (rst),
        .sw       (sw),
        .btn_r    (btn_r),
        .btn_l    (btn_l),
        .btn_u    (btn_u),
        .btn_d    (btn_d),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data),
        .led      (led)
    );

    // 4. Clock Generation (100MHz)
    always #5 clk = ~clk; // 10ns period

    // 5. UART Send Task (PC Simulation)
    // 8비트 데이터를 받아 Start bit -> Data bits -> Stop bit 순서로 보냄
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start Bit (Low)
            uart_rx = 0;
            #(BIT_PERIOD);

            // Data Bits (LSB First)
            for (i=0; i<8; i=i+1) begin
                uart_rx = data[i];
                #(BIT_PERIOD);
            end

            // Stop Bit (High)
            uart_rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // 6. Test Stimulus
    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;
        sw = 16'h0000;
        btn_r = 0; btn_l = 0; btn_u = 0; btn_d = 0;
        uart_rx = 1; // UART Idle state is High

        // Reset Sequence
        #100;
        rst = 0;
        #100;

        // --- Test 1: UART Command 'r' (Run/Stop) ---
        $display("Test 1: Sending 'r' (Run/Stop Toggle)...");
        uart_send_byte(8'h72); // ASCII 'r' = 0x72
        
        // 명령 처리 대기 (Decoder가 처리할 시간)
        #1000; 
        
        // 시계가 동작하는지 확인하기 위해 시간을 좀 둡니다.
        // (주의: 시뮬레이션에서 실제 1초를 기다리려면 너무 오래 걸리므로
        //  파형에서 msec 카운터가 올라가는지만 확인하세요)
        #500000; 

        // --- Test 2: UART Command '0' (Mode Toggle) ---
        $display("Test 2: Sending '0' (Mode Toggle)...");
        // 현재 led[0] 상태 확인 (초기엔 0)
        
        uart_send_byte(8'h30); // ASCII '0' = 0x30
        
        #1000;
        // led[0]이 토글되었는지 파형으로 확인

        // --- Test 3: Physical Button Test ---
        $display("Test 3: Physical Button Press...");
        btn_r = 1; // 버튼 누름
        #500000;   // 디바운싱 시간 고려 (시뮬레이션에선 파라미터 조절 안하면 오래 걸림)
        btn_r = 0;
        
        // --- Test 4: Loopback Check ---
        // uart_tx가 uart_rx를 따라 움직였는지 파형에서 확인 가능

        #100000;
        $display("Simulation Finished.");
        $stop;
    end

endmodule
