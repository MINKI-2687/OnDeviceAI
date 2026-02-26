`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;
endinterface  // adder_interface

// stimulus(vector)
class transaction;
    // rand  : 랜덤 패턴을 만듬 중복 가능
    // randc : 랜덤 패턴을 만드는데, 중복 불가능, 모든 값이 다 나와야 초기화 후 다시 만듬
    randc bit [31:0] a;
    randc bit [31:0] b;
    randc bit        mode;
    logic     [31:0] s;  // s, c는 rand 아님. 
    logic            c;  // X, Z도 있을 수 있으니 logic

    task display(string name);  // system task에서는 display 쓸 수 있음?
        $display("%t: [%s] a = %h, b = %h, mode = %h, s = %h, c = %h", $time,
                 name, a, b, mode, s, c);
    endtask  //display

    // 범위 지정 (a, b)
    /*constraint range {
        a > 10;
        b > 32'hffff_0000;
    }*/

    // 확률 지정 (8, 1, 1)
    /*constraint dist_pattern {
        a dist {
            0                   :/ 80,  // 80%
            32'hffff_ffff       :/ 10,  // 10%  
            [1 : 32'hffff_fffe] :/ 10   // 10%
        };
    }*/

    // 
    constraint list_pattern {a inside {[0 : 16]};}

endclass  //transaction

// generator for randomize stimulus
class generator;

    // handle
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_ev;

    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run(int count);
        repeat (count) begin
            tr = new();  // tr 생성
            tr.randomize();  // random tr 생성
            gen2drv_mbox.put(tr);  // mailbox에 tr을 put
            tr.display("GEN");
            @(gen_next_ev);  // scb를 event를 기다림
        end
    endtask

endclass  //generator

// driver
class driver;

    // handle
    transaction             tr;
    virtual adder_interface adder_if;
    mailbox #(transaction)  gen2drv_mbox;
    event                   mon_next_ev;

    // 외부와 연결할 내부 if handle 생성
    function new(mailbox#(transaction) gen2drv_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.adder_if     = adder_if;
        this.mon_next_ev  = mon_next_ev;
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction  // new()

    task run();
        forever begin
            gen2drv_mbox.get(
                tr);  // mailbox에서 들어온 tr을 get, 없으면 알아서 대기
            adder_if.a    = tr.a;
            adder_if.b    = tr.b;
            adder_if.mode = tr.mode;
            tr.display("DRV");
            #10;
            // 다 되면 mailbox의 내용은 사라짐
            // event generator (trigger 역할)
            ->mon_next_ev;
        end
    endtask

endclass  //driver

class monitor;

    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event mon_next_ev;
    virtual adder_interface adder_if;

    function new(mailbox#(transaction) mon2scb_mbox, event mon_next_ev,
                 virtual adder_interface adder_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.mon_next_ev  = mon_next_ev;
        this.adder_if     = adder_if;
    endfunction  //new()

    task run();
        forever begin
            @(mon_next_ev);
            tr      = new();
            tr.a    = adder_if.a;
            tr.b    = adder_if.b;
            tr.mode = adder_if.mode;
            tr.s    = adder_if.s;
            tr.c    = adder_if.c;
            mon2scb_mbox.put(tr);
            tr.display("MON");
        end

    endtask
endclass  //monitor

class scoreboard;

    transaction                   tr;
    mailbox #(transaction)        mon2scb_mbox;
    event                         gen_next_ev;
    bit                    [31:0] expected_sum;
    bit                           expected_carry;
    int                           pass_cnt,       fail_cnt;

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
    endfunction  //new()

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("SCB");
            // compare, pass, fail
            // generate for compare expected data
            if (!tr.mode) {expected_carry, expected_sum} = tr.a + tr.b;
            else {expected_carry, expected_sum} = tr.a - tr.b;
            if ((expected_sum == tr.s) && (expected_carry == tr.c)) begin
                $display("[PASS]: a = %h, b = %h, mode = %d, s = %h, c = %h",
                         tr.a, tr.b, tr.mode, tr.s, tr.c);
                pass_cnt++;
            end else begin
                $display("[FAIL]: a = %h, b = %h, mode = %d, s = %h, c = %h",
                         tr.a, tr.b, tr.mode, tr.s, tr.c);
                fail_cnt++;
                $display("expected sum = %h", expected_sum);
                $display("expected carry = %h", expected_carry);

            end
            ->gen_next_ev;
        end
    endtask

endclass  //scoreboard

class environment;

    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;
    mailbox #(transaction) gen2drv_mbox;  // gen -> drv
    mailbox #(transaction) mon2scb_mbox;  // mon -> scb
    event                  gen_next_ev;  // scb -> gen
    event                  mon_next_ev;  // drv -> mon

    int                    i;

    function new(virtual adder_interface adder_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen          = new(gen2drv_mbox, gen_next_ev);
        drv          = new(gen2drv_mbox, mon_next_ev, adder_if);
        mon          = new(mon2scb_mbox, mon_next_ev, adder_if);
        scb          = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        i = 100;  // gen 100번 실행
        // gen을 run하고 그 다음 drv를 run함. 한 줄씩 실행됨(begin end가 생략되어있음)
        fork  // 동시 실행
            gen.run(i);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #20;   // gen은 끝나서 나왔지만 아직 drv, mon, scb가 돌고 있으니 시간 여유를 둠.

        $display("______________________________");
        $display("** 32bit Adder Verification **");
        $display("------------------------------");
        $display("** Total Test cnt = %3d     **", i);
        $display("** Total pass cnt = %3d     **", scb.pass_cnt);
        $display("** Total fail cnt = %3d     **", scb.fail_cnt);
        $display("------------------------------");

        $stop;
    endtask
endclass  //environment

module tb_adder_verification ();

    adder_interface adder_if ();
    environment env;

    adder dut (
        .a   (adder_if.a),
        .b   (adder_if.b),
        .mode(adder_if.mode),
        .s   (adder_if.s),
        .c   (adder_if.c)
    );

    initial begin
        // 생성자 (constructor)
        env = new(adder_if);

        // 실행 exe
        env.run();
    end

endmodule
