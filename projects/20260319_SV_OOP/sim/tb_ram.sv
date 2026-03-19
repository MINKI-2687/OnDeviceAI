`timescale 1ns / 1ps

interface ram_if (
    input logic clk
);
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
endinterface  //ram_if

//
class test;
    virtual ram_if r_if;  // H/W 가 아님. (handler 느낌)

    function new(virtual ram_if r_if);
        this.r_if = r_if;
    endfunction  //new()

    // virtual task (덮어쓰기(override))가 가능하므로 
    // 자식 클래스에서 사용될 때 재정의하거나 내용을 바꿀 수 있음
    virtual task write(logic [7:0] waddr, logic [7:0] data);
        r_if.we    = 1;
        r_if.addr  = waddr;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  //

    virtual task read(logic [7:0] raddr);
        r_if.we   = 0;
        r_if.addr = raddr;
        @(posedge r_if.clk);
    endtask  //
endclass  //test

//
class test_burst extends test;

    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction  //new()

    task write_burst(logic [7:0] waddr, logic [7:0] data, int len);
        for (int i = 0; i < len; i++) begin
            super.write(waddr, data);  // 부모 클래스의 write
            waddr++;
        end
    endtask  //

    task write(logic [7:0] waddr, logic [7:0] data);  // 재정의
        r_if.we    = 1;
        r_if.addr  = waddr+1;
        r_if.wdata = data;
        @(posedge r_if.clk);
    endtask  //
endclass  //test_burst

//
class transaction;
    logic            we;
    rand logic [7:0] addr;
    rand logic [7:0] wdata;
    logic      [7:0] rdata;

    constraint c_addr {addr inside {[8'h00 : 8'h10]};}
    constraint c_wdata {wdata inside {[8'h10 : 8'h20]};}

    function print(string name);
        $display("[%s] we: %0d, addr: 0x%0x, wdata:0x%0x, rdata:0x%0x", name,
                 we, addr, wdata, rdata);
    endfunction  //new()
endclass  //transaction

//
class test_rand extends test;

    transaction tr;  // stack 영역에 메모리 공간이 잡힘

    function new(virtual ram_if r_if);
        super.new(r_if);
    endfunction  //new()

    task write_rand(int loop);
        repeat (loop) begin
            // heap 영역에 new 공간이 할당됨. 그리고 이후에 그 값들이 tr공간에 들어감?
            tr = new();
            tr.randomize();
            r_if.we    = 1;
            r_if.addr  = tr.addr;
            r_if.wdata = tr.wdata;
            @(posedge r_if.clk);
        end
    endtask  //
endclass  //test_rand 

//
module tb_ram ();
    logic     clk;
    // test는 객체를 만드는 틀? BTS는 handler 둘 다 지금은 객체가 아님
    test      BTS;
    test_rand BlackPink;

    ram_if r_if (clk);

    ram dut (
        .clk  (r_if.clk),
        .we   (r_if.we),
        .addr (r_if.addr),
        .wdata(r_if.wdata),
        .rdata(r_if.rdata)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // task ram_write(logic [7:0] waddr, logic [7:0] data);
    //     we    = 1;
    //     addr  = waddr;
    //     wdata = data;
    //     @(posedge clk);
    // endtask  //

    // task ram_read(logic [7:0] raddr);
    //     we   = 0;
    //     addr = raddr;
    //     @(posedge clk);
    // endtask  //

    initial begin
        repeat (5) @(posedge clk);
        // 실체화(instance) 해준다. new한 순간부터 BTS가 객체가 됨.
        BTS       = new(r_if);
        // BTS = new(virtual ram_if r_if) 와 같은 의미 S/W를 H/W와 연결하겠다.
        BlackPink = new(r_if);
        $display("addr = 0x%0h", BTS);
        $display("addr = 0x%0h", BlackPink);
        // OOP  (BTS 라는 주어가 있음)
        BTS.write(8'h00, 8'h01);
        BTS.write(8'h01, 8'h02);
        BTS.write(8'h02, 8'h03);
        BTS.write(8'h03, 8'h04);

        BlackPink.write_rand(10);

        // NOT OOP
        // write(8'h00, 8'h01);
        // write(8'h01, 8'h02);
        // write(8'h02, 8'h03);
        // write(8'h03, 8'h04);

        BTS.read(8'h00);
        BTS.read(8'h01);
        BTS.read(8'h02);
        BTS.read(8'h03);

        // read(8'h00);
        // read(8'h01);
        // read(8'h02);
        // read(8'h03);

        #20;
        $finish;
    end
endmodule
