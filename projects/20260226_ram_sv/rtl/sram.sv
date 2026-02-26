`timescale 1ns / 1ps

// 주소 저장 공간이 있는 메모리
module sram (
    input        clk,
    input  [3:0] addr,
    input  [7:0] wdata,
    input        we,
    output [7:0] rdata
);

    // 16개 word line, 8개 bit line

    reg [7:0] memory[0:15];

    always_ff @(posedge clk) begin
        if (we) begin
            memory[addr] <= wdata;
        end
        //else begin
        //    rdata<=memory[addr];
        //end
    end

    assign rdata = memory[addr];

endmodule
