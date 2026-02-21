`timescale 1ns / 1ps

module tb_controller_SR04 ();
    reg        clk;
    reg        rst;
    reg        btn_r;
    reg        echo;
    wire       o_trigger;
    wire [8:0] distance;

    wire       w_o_btn;

    controller_SR04 CNTL_dut (
        .clk      (clk),
        .rst      (rst),
        .btn_r    (w_o_btn),
        .echo     (echo),
        .o_trigger(o_trigger),
        .distance (distance)
    );

    btn_debounce BD_dut (
        .clk  (clk),
        .rst  (rst),
        .i_btn(btn_r),
        .o_btn(w_o_btn)
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

        #60_000_000;
        echo = 1;
        #580_000;
        echo = 0;

        #100_000;
        $stop;
    end
endmodule
