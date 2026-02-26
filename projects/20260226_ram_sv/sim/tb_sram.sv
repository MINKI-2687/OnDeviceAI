`timescale 1ns / 1ps

interface ram_interface (
    input clk
);
    logic [3:0] addr;  // rand값
    logic [7:0] wdata;  // rand값
    logic       we;  // rand값
    logic [7:0] rdata;  // logic값.
endinterface  //ram_interface

//////////////////////////////////////////////////////////////////////////////////////////////////////
// transaction
// data 상자. 단지 하드웨어에 넣을 입력값과 결과값을 담는 빈 공간. 
// rand라고 붙이면 랜덤 값을 받아들일 수 있는 변수.(실질적인 랜덤 변수는 monescbor가 생성)
// logic은 4state ; 결과값
// bit은 2staet; 입력값
// 처음: monescbor에선 입력값만 랜덤으로 채워짐 
// 중간: monitor 단계에선 하드웨어가 계산한 결과값을 채움
// 마지막: scoreboard단계에선 입력과 결과가 담겨 있는 상자에 대해서 정답인지 아닌지 채점.
// 그리고 드라이버는 tr에 적힌 입력값을 실제 하드웨어에 쏴줌.
// 즉 검증 공정을 거치면서 값이 점점 채워지는 클래스(핸들러).

class transaction;
    rand bit [3:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    logic    [7:0] rdata;
    // 이 기능이 필요해서, 또는 있어야만 의도한 동작을 하는 그런 게 아니고 
    // 시뮬레이션 상에서 이게 각 단계에서 값이 잘 들어 갔는지 확인하는 것을 쉽게 하기 위해서(사람이) 이러한 함수를 넣는 것.
    function void display(string name);
        $display("%t: [%s] we= %d, addr = %2h,wdata = %2h, rdata=%2h", $time,
                 name, we, addr, wdata, rdata);
    endfunction  //new()
    // void function. 리턴 타입이 없는 함수
    // 리턴값은 보통 결과값인데 이거는 있어도 되고 없어도 되고.
    // 베릴로그에선 항상 리턴이 있어야 했음.
    // function과 task 차이는 시간성분 있냐 없냐. 여기는 시간 성분 필요없어서 안함.
endclass  //transaction

//////////////////////////////////////////////////////////////////////////////////////////////////////
//monescbor
class generator;
    // class transaction을 호출할 handle을 준비.
    transaction tr;

    // tr만 취급하는 mailbox변수
    // 'mailbox'는 데이터를 주고 받을 통로로 정의하는 SV 문법. 예약어.
    // 만약 직접 데이터를 주고받는 기능을 구현하려면 매우 복잡함.
    // SV에선 그 모든 기능이 들어있는 도구를 만들어서 문법으로 제공.
    mailbox #(transaction) gen2drv_mbox;
    // mailbox는 reg, wire같은, 검증 환경(소프트웨어)에서 데이터를 나르는 역할의 데이터 타입.
    // #(transaction)은 파라미터화.  그냥 mailbox만 쓰면 아무 데이터나 마구잡이로 담을 수 있음.
    // 파라미터화를 하지 않으면 시뮬레이터가 잘못된 데이터가 들어가도 오류 안띄워주고 
    // drv로 넘길 때 에러가 발생할 수 있고 등등의 문제 발생.
    // gen2drv는 사용자가 정한 변수 이름.(인스턴스 핸들 이름)

    // 밖에서 들어온 변수와 내부 변수명 연결.
    // this는 이름이 같아서 생길 수 있는 문제를 명확히 함.
    // function new는 generator가 외부(environment)에서 호출되서 메모리에 올라갈 때, 딱 한번 '자동으로' 실행되는 함수.
    // ()는 함수에 전달할 매개변수.

    event gen_next_ev;  // 이게 있어야
    function new(mailbox#(transaction) gen2drv_mbox, event gen_next_ev);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_ev  = gen_next_ev;
        // this.gen2drv_mbox가 내가 위에서 정의한 변수명
        // 그냥 gen2drv_mbox가 바깥에서 받은 변수.
    endfunction  //new()

    // 이거는 '수동' 호출
    // task run은 실제로 일을 시작하라는 명령
    // ()안에 숫자만큼 반복하라는 것.
    task run(int run_count);
        repeat (run_count) begin
            tr = new();              // tr(transaction, handle로 간편하게.)을 생성하라는 것.; 빈 박스 생성
            tr.randomize();         // 빈 상자 안에 랜덤 변수들에 무작위 숫자를 채워넣음.
            gen2drv_mbox.put(
                tr);   // 실제 tr안에 있는 값을 gen2drv_mbox로 실어 내보냄.
            tr.display("gen");
            @(gen_next_ev);
        end
    endtask  //run
endclass  //generator

//////////////////////////////////////////////////////////////////////////////////////////////////////
//driver
class driver;

    transaction            tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface  ram_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if       = ram_if;
    endfunction  //new()

    task run();
        forever begin
            //메세지 올때까지 기다려야
            gen2drv_mbox.get(tr);
            @(negedge ram_if.clk);
            ram_if.addr  = tr.addr;
            ram_if.wdata = tr.wdata;
            ram_if.we    = tr.we;
            tr.display("drv");
        end
    endtask  //run
endclass  //driver

//////////////////////////////////////////////////////////////////////////////////////////////////////
//monitor
class monitor;

    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface  ram_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual ram_interface ram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if       = ram_if;
    endfunction  //new()

    task run();
        forever begin
            @(posedge ram_if.clk);
            #1;
            tr       = new();
            tr.addr  = ram_if.addr;
            tr.we    = ram_if.we;
            tr.wdata = ram_if.wdata;
            tr.rdata = ram_if.rdata;
            mon2scb_mbox.put(tr);
            tr.display("mon");
        end
    endtask  //run
endclass  //driver

//////////////////////////////////////////////////////////////////////////////////////////////////////
//scoreboard

class scoreboard;

    transaction            tr;
    mailbox #(transaction) mon2scb_mbox;
    event                  gen_next_ev;

    // coverage
    covergroup cg_sram;
        cp_addr: coverpoint tr.addr {
            bins min = {0}; bins max = {15}; bins mid = {[1 : 14]};
        }
    endgroup

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_ev);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen_next_ev  = gen_next_ev;
        cg_sram           = new();
    endfunction  //new()

    task run();
        logic [7:0] expected_ram[0:15];
        forever begin
            mon2scb_mbox.get(tr);
            tr.display("scb");

            cg_sram.sample();
            //pass,fail
            if (tr.we) begin
                expected_ram[tr.addr] = tr.wdata;
                $display("%2h", expected_ram[tr.addr]);
            end else begin
                // X or Z 값도 비교할 수 있음 ( === )
                if (expected_ram[tr.addr] === tr.rdata) $display("Pass");
                else
                    $display(
                        "Fail : expected data = %2h, rdata = %2h",
                        expected_ram[tr.addr],
                        tr.rdata
                    );
            end
            //next stimulus
            ->gen_next_ev;
        end
    endtask  //run
endclass  //scoreboard

//////////////////////////////////////////////////////////////////////////////////////////////////////
//environment

class environment;
    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    event                  gen_next_ev;

    function new(virtual ram_interface ram_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen          = new(gen2drv_mbox, gen_next_ev);
        drv          = new(gen2drv_mbox, ram_if);
        mon          = new(mon2scb_mbox, ram_if);
        scb          = new(mon2scb_mbox, gen_next_ev);
    endfunction  //new()

    task run();
        fork
            gen.run(10);
            mon.run();
            drv.run();
            scb.run();
        join_any
        #10;
        $display("coverage addr = %d", scb.cg_sram.get_inst_coverage());
        $stop;
    endtask  //run
endclass  //environment

//////////////////////////////////////////////////////////////////////////////////////////////////////
//DUT
module tb_sram ();

    logic clk;

    ram_interface ram_if (clk);
    environment env;

    sram DUT (
        .clk  (clk),
        .addr (ram_if.addr),
        .wdata(ram_if.wdata),
        .we   (ram_if.we),
        .rdata(ram_if.rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        env = new(ram_if);
        env.run();
    end

endmodule
