`timescale 1ns / 1ps

module controller_SR04 (
    input                    clk,
    input                    rst,
    input                    btn_r,      // 탑 모듈 연결용
    input                    echo,
    output                   o_trigger,
    output [$clog2(400)-1:0] distance
);

    wire w_tick_1us;

    tick_gen_1Mhz U_TICK_GEN (
        .clk        (clk),
        .rst        (rst),
        .o_tick_1Mhz(w_tick_1us)
    );

    parameter IDLE = 2'd0, START = 2'd1;
    parameter WAIT = 2'd2, DISTANCE = 2'd3;

    reg [1:0] c_state, n_state;
    reg [3:0] trig_cnt_reg, trig_cnt_next;

    // 60ms(60000us) 대기를 위해 레지스터 크기를 16비트로 확장
    reg [15:0] echo_time_reg, echo_time_next;
    reg [$clog2(400)-1:0] distance_reg, distance_next;

    reg sync_echo_1, sync_echo_2;

    assign o_trigger = (c_state == START) ? 1'b1 : 1'b0;
    assign distance  = distance_reg;

    // echo synchronizer
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            sync_echo_1 <= 0;
            sync_echo_2 <= 0;
        end else begin
            sync_echo_1 <= echo;
            sync_echo_2 <= sync_echo_1;
        end
    end

    // state & data register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state       <= IDLE;
            distance_reg  <= 0;
            trig_cnt_reg  <= 0;
            echo_time_reg <= 0;
        end else begin
            c_state       <= n_state;
            distance_reg  <= distance_next;
            trig_cnt_reg  <= trig_cnt_next;
            echo_time_reg <= echo_time_next;
        end
    end

    // output CL
    always @(*) begin
        n_state        = c_state;
        trig_cnt_next  = trig_cnt_reg;
        echo_time_next = echo_time_reg;
        distance_next  = distance_reg;

        case (c_state)
            IDLE: begin
                // 버튼이 없어도 60ms마다 알아서 START로 넘어감 (자동 측정)
                if (w_tick_1us) begin
                    if (echo_time_reg >= 60000) begin // 60ms 대기 (초음파 충돌 방지)
                        echo_time_next = 0;
                        n_state = START;
                    end else begin
                        echo_time_next = echo_time_reg + 1;
                    end
                end
            end
            START: begin
                if (w_tick_1us) begin
                    if (trig_cnt_reg == 10) begin
                        trig_cnt_next = 0;
                        echo_time_next = 0;  // 측정 준비
                        n_state = WAIT;
                    end else begin
                        trig_cnt_next = trig_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (sync_echo_2) begin
                    n_state = DISTANCE;
                    echo_time_next = 0;  // 진짜 시간 측정 시작
                end else if (w_tick_1us) begin
                    echo_time_next = echo_time_reg + 1;
                    // 타임아웃: 허공에 쏴서 30ms 동안 Echo가 안 오면 강제 리셋
                    if (echo_time_reg > 30000) begin
                        n_state = IDLE;
                        echo_time_next = 0;
                    end
                end
            end
            DISTANCE: begin
                if (!sync_echo_2) begin  // 측정이 끝났을 때
                    distance_next = (echo_time_reg * 1130) >> 16;
                    n_state = IDLE;     //  측정이 끝나면 IDLE로 가서 60ms 쉬고 다시 시작
                    echo_time_next = 0;
                end else if (w_tick_1us) begin
                    echo_time_next = echo_time_reg + 1;
                    // 타임아웃: 거리가 너무 멀면(약 4m 이상) 에러 방지용 리셋
                    if (echo_time_reg > 30000) begin
                        n_state = IDLE;
                        echo_time_next = 0;
                    end
                end
            end
        endcase
    end
endmodule
