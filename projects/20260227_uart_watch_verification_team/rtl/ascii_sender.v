`timescale 1ns / 1ps

module ASCII_Sender (
    input        clk,
    input        reset,
    input        i_send_trig,
    input        i_tx_busy,
    
    input [4:0]  i_hour,
    input [5:0]  i_min,
    input [5:0]  i_sec,

    output reg [7:0] o_send_to_tx_data,
    output reg       o_send_to_tx_start,
    output           o_is_sending
);

    localparam IDLE       = 3'b000;
    localparam SEND       = 3'b001;
    localparam WAIT_BUSY  = 3'b010;
    localparam WAIT_DONE  = 3'b011;

    reg [2:0] state;
    reg [3:0] char_idx;
    
    // 연산 결과를 저장할 레지스터 (나머지 연산 제거용)
    reg [3:0] h_ten, h_one;
    reg [3:0] m_ten, m_one;
    reg [3:0] s_ten, s_one;

    assign o_is_sending = (state != IDLE);

    // 1. 보낼 문자 결정 (조합 논리는 이제 단순한 MUX 역할만 수행)
    reg [7:0] w_ascii_char;
    always @(*) begin
        case (char_idx)
            0: w_ascii_char = 8'h30 + h_ten;
            1: w_ascii_char = 8'h30 + h_one;
            2: w_ascii_char = 8'h3A; // ":"
            3: w_ascii_char = 8'h30 + m_ten;
            4: w_ascii_char = 8'h30 + m_one;
            5: w_ascii_char = 8'h3A; // ":"
            6: w_ascii_char = 8'h30 + s_ten;
            7: w_ascii_char = 8'h30 + s_one;
            8: w_ascii_char = 8'h0D; // CR
            9: w_ascii_char = 8'h0A; // LF
            default: w_ascii_char = 8'h20;
        endcase
    end

    // 2. FSM 및 데이터 캡처
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            char_idx <= 0;
            o_send_to_tx_start <= 0;
            {h_ten, h_one, m_ten, m_one, s_ten, s_one} <= 0;
        end else begin
            case (state)
                IDLE: begin
                    char_idx <= 0;
                    o_send_to_tx_start <= 0;
                    if (i_send_trig) begin
                        // 트리거 시점에만 저장 
                        h_ten <= i_hour / 10; h_one <= i_hour % 10;
                        m_ten <= i_min / 10;  m_one <= i_min % 10;
                        s_ten <= i_sec / 10;  s_one <= i_sec % 10;
                        state <= SEND;
                    end
                end

                SEND: begin
                    // UART가 이전 전송(예: 'p' 키 자체의 에코)을 끝낼 때까지 대기
                    if (!i_tx_busy) begin
                        o_send_to_tx_data  <= w_ascii_char;
                        o_send_to_tx_start <= 1'b1;
                        state      <= WAIT_BUSY;
                    end
                end

                WAIT_BUSY: begin
                    if (i_tx_busy) begin
                        o_send_to_tx_start <= 1'b0;
                        state      <= WAIT_DONE;
                    end
                end

                WAIT_DONE: begin
                    if (!i_tx_busy) begin
                        if (char_idx == 9) state <= IDLE;
                        else begin
                            char_idx <= char_idx + 1;
                            state    <= SEND;
                        end
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule