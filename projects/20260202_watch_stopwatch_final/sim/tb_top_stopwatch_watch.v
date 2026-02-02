`timescale 1ns / 1ps

module tb_top_stopwatch_watch ();
    reg         clk;
    reg         reset;
    // sw[0] up/down // sw[1] watch select // sw[2] sel display // sw[3] watch time setting
    // sw[15:12] 자릿수 선택 스위치
    reg  [15:0] sw;
    reg         btn_r;  // i_run_stop     
    reg         btn_l;  // i_clear
    reg         btn_u;  // watch up setting
    reg         btn_d;  // watch down setting
    wire [ 3:0] fnd_digit;
    wire [ 7:0] fnd_data;

    top_stopwatch_watch dut (
        .clk      (clk),
        .reset    (reset),
        .sw       (sw),
        .btn_r    (btn_r),      // i_run_stop     
        .btn_l    (btn_l),      // i_clear
        .btn_u    (btn_u),      // watch up setting
        .btn_d    (btn_d),      // watch down setting
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    // push button task
    task push_btn_r;
        begin
            btn_r = 1;
            #200_000;
            btn_r = 0;
            #200_000;
        end
    endtask
    task push_btn_l;
        begin
            btn_l = 1;
            #200_000;
            btn_l = 0;
            #200_000;
        end
    endtask
    task push_btn_u;
        begin
            btn_u = 1;
            #200_000;
            btn_u = 0;
            #200_000;
        end
    endtask
    task push_btn_d;
        begin
            btn_d = 1;
            #200_000;
            btn_d = 0;
            #200_000;
        end
    endtask

    initial begin
        // init value
        clk = 0;
        reset = 1;
        sw = 16'h0000;
        btn_r = 0;
        btn_l = 0;
        btn_u = 0;
        btn_d = 0;
        #1_000;
        reset = 0;
        #1_000;

        // satch test
        sw[1] = 1;  // watch mode
        sw[0] = 0;  // up count mode
        #1_000;

        // reset -> IDLE state -> time stop
        #1_000_000;

        // start
        push_btn_r;

        // 10 up count during 100ms
        #100_000_000;

        // Watch down test
        sw[0] = 1;  // Down count mode 
        #150_000_000;  // 150ms (12:00:00.10 -> 11:59:59.99 -> 11:59:59:95)

        // watch setting mode
        sw[3]  = 1;  // setting mode on -> time stop

        // change hour 11 -> btn_u 5 times -> hour(16) -> btn_d 2 times -> hour(14)
        sw[15] = 1;
        repeat (5) push_btn_u;
        #500_000;
        repeat (2) push_btn_d;
        #500_000;
        sw[15] = 0;

        // change minute 59 -> btn_u 10 times -> result minute 9
        sw[14] = 1;
        repeat (10) push_btn_u;
        #500_000;
        sw[14] = 0;

        // change second 59 -> btn_d 20 times -> result second 39
        sw[13] = 1;
        repeat (20) push_btn_d;
        #500_000;
        sw[13] = 0;

        sw[3]  = 0;  // setting mode off -> watch time run
        #100_000_000;  // 100ms
        push_btn_l;  // Clear

        //
        //
        // stopwatch test
        sw[1] = 0;  // stopwatch mode (init 00:00:00:00)
        sw[0] = 0;  // up count mode

        #1000;
        push_btn_r;  // run
        #200_000_000;  // 20 count up during 200ms

        // clear for check down value
        push_btn_l;  // clear
        sw[0] = 1;  // down count mode
        push_btn_r;  // run
        #50_000_000;  // 5 count down during 50ms

        // stopwatch stop and clear
        push_btn_r;  // stop
        #20_000_000;  // stop during 20ms
        push_btn_l;  // clear
        #10_000_000;  // check 00:00:00:00 value

        $stop;
    end

endmodule
