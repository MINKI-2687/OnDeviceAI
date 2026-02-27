`timescale 1ns / 1ps

module tb_fifo ();

    reg clk, rst, push, pop;
    reg  [7:0] push_data;
    wire [7:0] pop_data;
    wire full, empty;

    // random
    reg rand_pop, rand_push;
    reg [7:0] rand_data;
    reg [7:0] compare_data[0:15];  // buffer
    reg [3:0] push_cnt, pop_cnt;

    integer i, pass_cnt, fail_cnt;

    fifo_sv dut (
        .clk  (clk),
        .rst  (rst),
        .we   (push),
        .re   (pop),
        .wdata(push_data),
        .rdata(pop_data),
        .full (full),
        .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk       = 0;
        rst       = 1;
        push      = 0;
        push_data = 0;
        pop       = 0;

        i         = 0;
        pass_cnt  = 0;
        fail_cnt  = 0;
        rand_data = 0;
        rand_pop  = 0;
        rand_push = 0;
        push_cnt  = 0;
        pop_cnt   = 0;

        @(posedge clk);
        @(posedge clk);

        rst = 0;

        // push 5 times
        for (i = 0; i < 16; i = i + 1) begin
            #1;
            push      = 1;
            push_data = 8'h61 + i;  // 'a'
            @(posedge clk);
        end
        push = 0;

        // pop 5 times
        for (i = 0; i < 16; i = i + 1) begin
            pop = 1;
            @(posedge clk);
        end
        pop       = 0;

        // push 1 time
        push      = 1;
        push_data = 8'haa;
        @(posedge clk);
        push = 0;
        @(posedge clk);

        // push, pop
        for (i = 0; i < 16; i = i + 1) begin
            push      = 1;
            pop       = 1;
            push_data = i;
            @(posedge clk);
        end

        push = 0;
        pop  = 1;
        @(posedge clk);
        @(posedge clk);
        pop = 0;

        @(posedge clk);

        // random test
        for (i = 0; i < 256; i = i + 1) begin
            rand_push = $random % 2;
            rand_pop  = $random % 2;
            rand_data = $random % 256;
            push      = rand_push;
            push_data = rand_data;
            pop       = rand_pop;

            #4;
            if (push & (!full)) begin
                compare_data[push_cnt] = rand_data;
                push_cnt               = push_cnt + 1;
            end
            if (pop & (!empty)) begin
                if (pop_data == compare_data[pop_cnt]) begin
                    $monitor("%t : pass, pop_data = %h, compare data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                    pass_cnt = pass_cnt + 1;
                end else begin
                    $monitor("%t : fail!!, pop_data = %h, compare data = %h",
                             $time, pop_data, compare_data[pop_cnt]);
                    fail_cnt = fail_cnt + 1;
                end
                pop_cnt = pop_cnt + 1;
            end
            @(posedge clk);
        end

        $display("%t : pass count = %d, fail count = %d", $time, pass_cnt,
                 fail_cnt);

        repeat (5) @(posedge clk);

        $stop;
    end
endmodule