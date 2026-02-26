`timescale 1ns / 1ps

interface adder_interface;
    logic [31:0] a;
    logic [31:0] b;
    logic        mode;
    logic [31:0] s;
    logic        c;
endinterface  //adder_interface

class transaction;

    // rand 값으로 선언(아직 랜덤값이 생성된 건 아님)
    // rand 값 생성을 위한 keyword
    rand bit [31:0] a;
    rand bit [31:0] b;
    bit             mode;

endclass  //transaction

class generator;

    // transaction 클래스 타입의 handle인 tr 선언
    transaction             tr;

    // generator안에 외부 interface와 연결하기 위해
    // adder_interface라는 data type을 선언 후 이름 설정
    // generator(SW)와 interface(HW)를 연결하기 위해 virtual이라고 선언
    virtual adder_interface adder_interf_gen;

    // class에서 제공되는 생성자 (외부 if를 가져오기 위한 생성자)
    // 나중에 tb에 new() 함수가 불리면 그때 쓰임
    function new(virtual adder_interface adder_interf_ext);
        // generator 내부의 if와 외부의 if를 연결하기 위해
        // adder_interface라는 data type을 선언 후 ext라고 이름 설정
        // 이 둘을 묶어줌 -> 내부 if와 외부 if가 연결됨.
        this.adder_interf_gen = adder_interf_ext;
        // tr 생성
        tr                    = new();
    endfunction  //new()

    task run();
        tr.randomize();  // class에서 제공해주는 함수
        tr.mode               = 0;
        adder_interf_gen.a    = tr.a;
        adder_interf_gen.b    = tr.b;
        adder_interf_gen.mode = tr.mode;

        // drive (위에서 생성된 rand 값을 내부 if에 위치 시킨 뒤, 10ns를 delay)
        #10;
    endtask

endclass  //generator

module tb_adder_sv ();
    // 원래는 있었는데, 밑에서 interface로 연결해주기 때문에
    // 냅두면 multiple drive되어 삭제함
    // logic [31:0] a, b, s;
    // logic mode, c;

    adder_interface adder_interf ();

    // class generator를 선언
    // gen: generator 객체를 가리키는 handle
    // 밑에서 new로 동적 메모리 할당을 위한 이름, 생성은 new가 실행되면 그때 생성됨
    generator gen;

    adder dut (
        .a   (adder_interf.a),
        .b   (adder_interf.b),
        .mode(adder_interf.mode),
        .s   (adder_interf.s),
        .c   (adder_interf.c)
    );

    initial begin
        // class generator를 생성
        // generator class의 function new를 실행
        // new 생성자
        // generator gen; 은 객체가 아닌 핸들만 선언한 상태, 값은 null
        // SystemVerilog의 class는 기본적으로 동적 할당을 따릅니다.
        // gen = new(adder_interf); 처럼 new() 생성자를 호출하여 객체를 동적으로 메모리에 할당
        // new()가 실행되는 순간, gen 객체가 생성되면서 
        // 그 내부의 멤버 변수인 tr 핸들과 vif 핸들도 함께 메모리에 생김
        gen = new(adder_interf);
        gen.run();
        $stop;

    end
endmodule
