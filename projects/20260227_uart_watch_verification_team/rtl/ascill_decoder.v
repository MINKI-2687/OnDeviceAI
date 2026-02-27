`timescale 1ns / 1ps

module ascii2btn_decoder (
    input       clk,
    input       reset,
    input       i_rx_done,  // UART 데이터 도착 알림
    input [7:0] i_rx_data,  // UART 데이터

    // [출력] 가상 버튼 (Pulse)
    output reg o_btn_L,
    output reg o_btn_R,
    output reg o_btn_C,
    output reg o_btn_U,
    output reg o_btn_D,

    // [출력] 가상 스위치 (Level)
    output reg o_sw_0,  // '0'번 키 -> sw[0]
    output reg o_sw_1,  // '1'번 키 -> sw[1]
    output reg o_sw_2,  // '2'번 키 -> sw[2] (모드)


    //ASCII SENDER
    output reg o_send_trig
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 리셋 시 모두 0으로 끔
            o_btn_L <= 0;
            o_btn_R <= 0;
            o_btn_C <= 0;
            o_btn_U <= 0;
            o_btn_D <= 0;
            o_sw_0  <= 0;
            o_sw_1  <= 0;
            o_sw_2  <= 0;
        end else begin
            // 1. 버튼은 매 클럭 0으로 자동 복귀 (Pulse 생성 원리)
            o_btn_L <= 0;
            o_btn_R <= 0;
            o_btn_C <= 0;
            o_btn_U <= 0;
            o_btn_D <= 0;
            o_send_trig <= 1'b0;
            // ★ 스위치는 여기서 0으로 만들지 않음! (상태 유지해야 하니까)

            // 2. 키보드 입력 들어왔을 때 ('딩동' 울림)
            if (i_rx_done) begin
                case (i_rx_data)
                    // --- 버튼: 누르면 1 클럭만 1이 됨 ---
                    "l", "L": o_btn_L <= 1'b1;
                    "r", "R": o_btn_R <= 1'b1;
                    "c", "C": o_btn_C <= 1'b1;
                    "u", "U": o_btn_U <= 1'b1;
                    "d", "D": o_btn_D <= 1'b1;
                    "p", "P": o_send_trig <= 1'b1;

                    // --- 스위치: 누를 때마다 켜짐/꺼짐 반전 (Toggle) ---
                    "0": o_sw_0 <= ~o_sw_0;
                    "1": o_sw_1 <= ~o_sw_1;
                    "2": o_sw_2 <= ~o_sw_2;

                endcase
            end
        end
    end

endmodule
