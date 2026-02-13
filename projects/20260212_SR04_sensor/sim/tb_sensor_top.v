`timescale 1ns / 1ps

module tb_sensor_top ();
    reg        clk;
    reg        rst;
    reg        btn_r;
    reg        echo;
    wire       o_trigger;
    wire [3:0] fnd_digit;
    wire [7:0] fnd_data;

    sensor_top dut (
        .clk      (clk),
        .rst      (rst),
        .btn_r    (btn_r),
        .echo     (echo),
        .o_trigger(o_trigger),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    task push_btn_r;
        begin
            btn_r = 1;
            #100_000;
            btn_r = 0;
            #100_000;
        end
    endtask

    initial begin
        clk   = 0;
        rst   = 1;
        btn_r = 0;
        echo  = 0;
        #20;
        rst = 0;

        #50;
        push_btn_r;

        #15_000;
        echo = 1;
        #680_000;
        echo = 0;

        #100_000;
        $stop;
    end

endmodule
