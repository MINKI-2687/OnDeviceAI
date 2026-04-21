`timescale 1ns / 1ps

module tb_axi4_lite_slave ();
    // Global & AXI Signals
    logic        ACLK;
    logic        ARESETn;
    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;

    // DUT 인스턴스 (Slave)
    axi4_lite_slave dut (.*);

    // Clock Generation
    always #5 ACLK = ~ACLK;

    // ---------------------------------------------------------
    // 가상의 Master BFM Tasks
    // ---------------------------------------------------------
    task automatic master_write(input [31:0] waddr, input [31:0] wdata);
        // 주소와 데이터를 버스에 인가
        AWADDR  <= waddr;
        AWVALID <= 1'b1;
        WDATA   <= wdata;
        WVALID  <= 1'b1;
        BREADY  <= 1'b1;  // 응답 받을 준비

        // AW채널과 W채널이 각각 독립적으로 READY를 받을 때까지 대기
        fork
            begin
                do @(posedge ACLK); while (!AWREADY);
                AWVALID <= 1'b0;
            end
            begin
                do @(posedge ACLK); while (!WREADY);
                WVALID <= 1'b0;
            end
        join

        // B채널 응답 대기
        do @(posedge ACLK); while (!BVALID);
        BREADY <= 1'b0;
        $display("[%0t] MASTER_BFM: Write Done. ADDR=%0h, DATA=%0h", $time,
                 waddr, wdata);
    endtask

    task automatic master_read(input [31:0] raddr, input [31:0] expected_data);
        ARADDR  <= raddr;
        ARVALID <= 1'b1;
        RREADY  <= 1'b1;

        // AR채널 주소 전달 대기
        do @(posedge ACLK); while (!ARREADY);
        ARVALID <= 1'b0;

        // R채널 데이터 수신 대기
        do @(posedge ACLK); while (!RVALID);
        RREADY <= 1'b0;

        // Self-Checking (자동 검증)
        if (RDATA === expected_data)
            $display(
                "[%0t] MASTER_BFM: Read PASS! ADDR=%0h, RDATA=%0h",
                $time,
                raddr,
                RDATA
            );
        else
            $error(
                "[%0t] MASTER_BFM: Read FAIL! Expected %0h but got %0h",
                $time,
                expected_data,
                RDATA
            );
    endtask

    // ---------------------------------------------------------
    // Test Scenario
    // ---------------------------------------------------------
    initial begin
        ACLK = 0;
        ARESETn = 0;  // Active-Low Reset
        AWVALID = 0;
        WVALID = 0;
        BREADY = 0;
        ARVALID = 0;
        RREADY = 0;

        repeat (5) @(posedge ACLK);
        ARESETn = 1;
        repeat (5) @(posedge ACLK);

        $display("--- TEST START: Single Write & Read Back ---");
        master_write(32'h0000_0004, 32'hDEADBEEF);
        repeat (2) @(posedge ACLK);
        master_read(32'h0000_0004, 32'hDEADBEEF);

        repeat (10) @(posedge ACLK);
        $finish;
    end
endmodule
