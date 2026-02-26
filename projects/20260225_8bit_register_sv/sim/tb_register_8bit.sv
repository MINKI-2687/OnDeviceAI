`timescale 1ns / 1ps

interface register_interface ();

    logic       clk;
    logic       rst;
    logic       we;
    logic [7:0] wdata;
    logic [7:0] rdata;

    // assert (디버깅할 때 많이 씀)
    property preset_check;
        @(posedge clk) rst |=> (rdata == 0);
    endproperty
    reg_reset_check :
    assert property (preset_check)
    else $display("%t: Assert error : reset check", $time);
    // 시뮬 결과 보면 15ns에 reset이 풀린걸로 인지 <- 틀림

endinterface  // register_interface

class transaction;

    rand bit we;
    rand bit [7:0] wdata;
    logic    [7:0] rdata;

    task display(string name);
        $display("%t : [%s] we = %d, wdata = %h, rdata = %h", $time, name, we,
                 wdata, rdata);
    endtask

endclass  //transaction

class generator;

    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    event                  gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr);
            tr.display("GEN");
            @(gen_next_ev);
        end
    endtask
endclass  //generator

class driver;

    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual register_interface register_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual register_interface register_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.register_if  = register_if;
    endfunction  //new()

    task preset();
        // register F/F reset
        register_if.clk = 0;
        register_if.rst = 1;
        @(posedge register_if.clk);
        @(posedge register_if.clk);
        register_if.rst = 0;
        @(posedge register_if.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(negedge register_if.clk);
            register_if.we    = tr.we;
            register_if.wdata = tr.wdata;
            tr.display("DRV");
        end
    endtask
endclass  //driver

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface register_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual register_interface register_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.register_if  = register_if;
    endfunction  //new()

    task run();
        forever begin
            tr = new();
            @(posedge register_if.clk);
            #1;
            tr.we    = register_if.we;
            tr.wdata = register_if.wdata;
            tr.rdata = register_if.rdata;
            mon2scb_mbox.put(tr);
            tr.display("MON");
        end
    endtask
endclass  //monitor

class scoreboard;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            if (tr.we) begin
                if (tr.wdata == tr.rdata) begin
                    $display("%t : Pass : wdata = %h, rdata = %h", $time,
                             tr.wdata, tr.rdata);
                end else begin
                    $display("%t : Fail : wdata = %h, rdata = %h", $time,
                             tr.wdata, tr.rdata);
                end
            end
            tr.display("SCB");
            ->gen_next_ev;
        end
    endtask

endclass  //scoreboard

class environment;

    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  gen_next_ev;

    function new(virtual register_interface register_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen          = new(gen2drv_mbox, gen_next_ev);
        drv          = new(gen2drv_mbox, register_if);
        mon          = new(mon2scb_mbox, register_if);
        scb          = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;
        $stop;

    endtask

endclass  //environment

module tb_register_8bit ();

    register_interface register_if ();

    environment env;

    register_8bit dut (
        .clk  (register_if.clk),
        .rst  (register_if.rst),
        .we   (register_if.we),
        .wdata(register_if.wdata),
        .rdata(register_if.rdata)
    );

    always #5 register_if.clk = ~register_if.clk;

    initial begin
        //        register_if.clk = 0;
        //        register_if.rst = 1;
        env = new(register_if);
        env.run();

    end
endmodule
