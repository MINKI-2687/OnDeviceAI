`timescale 1ns / 1ps

module register_8bit (
    input              clk,
    input              rst,
    // 데이터 유지, 버스 시스템에서 선택적 저장, 전력 소모(값이 바뀔 때가 가장 큼, we로 제어)
    input              we,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            rdata <= 8'h0;
        end else if (we) begin
            rdata <= wdata;
        end
    end

endmodule
