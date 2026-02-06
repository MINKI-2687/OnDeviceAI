`timescale 1ns / 1ps

module sw_control_unit (
    input      clk,
    input      reset,
    input      i_mode_sel,
    input      i_mode,
    input      i_run_stop,
    input      i_clear,
    output     o_mode,
    output reg o_run_stop,
    output reg o_clear
);

    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;

    // reg variable
    reg [1:0] current_st, next_st;

    assign o_mode = i_mode;

    // state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= STOP;
        end else begin
            current_st <= next_st;
        end
    end

    // next_st CL
    always @(*) begin
        next_st    = current_st;  // init state
        o_run_stop = (current_st == RUN) ? 1'b1 : 1'b0;
        o_clear    = (current_st == CLEAR) ? 1'b1 : 1'b0;
        if (!i_mode_sel) begin
            case (current_st)
                STOP: begin
                    // moore output
                    if (i_run_stop) begin
                        next_st = RUN;
                    end else if (i_clear) begin
                        next_st = CLEAR;
                    end
                end
                RUN: begin
                    if (i_run_stop) begin
                        next_st = STOP;
                    end else if (i_clear) begin
                        next_st = CLEAR;
                    end
                end
                CLEAR: begin
                    next_st = STOP;
                end
            endcase
        end
    end

endmodule

module watch_control_unit (
    input       clk,
    input       reset,
    input       i_setting,
    input       i_run,
    input       i_btn_up,
    input       i_btn_down,
    input       i_mode,
    input       i_mode_sel,
    input       i_clear,
    input [3:0] i_digit_sel, // 자릿수 선택 스위치용

    output     o_mode,
    output reg o_run,
    output reg o_clear,

    output reg o_hour_digit,
    output reg o_min_digit,
    output reg o_sec_digit,
    output reg o_msec_digit
);

    parameter IDLE = 2'b00, RUN = 2'b01, STOP = 2'b10, CLEAR = 2'b11;

    // reg variable
    reg [1:0] current_st, next_st;

    // 설정 모드 일때는 내려가는 btn, 평소에는 그냥 감소하는 btn
    assign o_mode = (current_st == STOP) ? i_btn_down : i_mode;

    // state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_st <= IDLE;
        end else begin
            current_st <= next_st;
        end
    end

    // next_st CL
    always @(*) begin
        next_st      = current_st;  // init state
        o_run        = (current_st == RUN) ? 1'b1 : 1'b0;
        o_clear      = (current_st == CLEAR) ? 1'b1 : 1'b0;
        o_hour_digit = 1'b0;
        o_min_digit  = 1'b0;
        o_sec_digit  = 1'b0;
        o_msec_digit = 1'b0;
        if (i_mode_sel) begin
            case (current_st)
                // moore output
                IDLE: begin
                    if (i_setting) begin
                        next_st = STOP;
                    end else if (i_run) begin
                        next_st = RUN;
                    end
                end
                STOP: begin
                    if (i_btn_up || i_btn_down) begin
                        if (i_digit_sel[3])
                            o_hour_digit = 1'b1;  // sw[15] 켜지면 hour 수정
                        else if (i_digit_sel[2])
                            o_min_digit = 1'b1;  // sw[14] 켜지면 min 수정
                        else if (i_digit_sel[1])
                            o_sec_digit = 1'b1;  // sw[13] 켜지면 sec 수정
                        else if (i_digit_sel[0])
                            o_msec_digit = 1'b1;  // sw[12] 켜지면 msec 수정
                    end else if (!i_setting) begin
                        next_st = RUN;  // 설정 모드 해제 시 다시 작동
                    end else if (i_clear) begin
                        next_st = CLEAR;
                    end
                end
                RUN: begin
                    if (i_setting) begin
                        next_st = STOP;
                    end else if (i_clear) begin
                        next_st = CLEAR;
                    end
                end
                CLEAR: begin
                    next_st = STOP; // STOP이지만 실제 보드에선 바로 동작한다.
                    // 그 이유는 stop으로 가자마자 setting이 0인 조건을 발견하여 RUN 상태로 가기 때문
                end
            endcase
        end
    end

endmodule
