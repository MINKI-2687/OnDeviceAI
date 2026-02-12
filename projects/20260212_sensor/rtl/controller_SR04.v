`timescale 1ns / 1ps

module controller_SR04 (
    input         clk,
    input         rst,
    input         btn_r,       // start
    input         i_tick_1us,
    input         echo,
    output        o_trigger,
    output [23:0] distance
);

    parameter IDLE = 2'd0, START = 2'd1;
    parameter WAIT = 2'd2, DISTANCE = 2'd3;

    reg [1:0] c_state, n_state;
    reg [3:0] trig_cnt_reg, trig_cnt_next;
    reg [23:0] echo_time_reg, echo_time_next;
    reg [23:0] distance_reg, distance_next;

    assign o_trigger = (c_state == START) ? 1'b1 : 1'b0;
    assign distance  = distance_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state       <= IDLE;
            trig_cnt_reg  <= 0;
            echo_time_reg <= 0;
            distance_reg  <= 0;
        end else begin
            c_state       <= n_state;
            trig_cnt_reg  <= trig_cnt_next;
            echo_time_reg <= echo_time_next;
            distance_reg  <= distance_next;
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
                trig_cnt_next  = 0;
                echo_time_next = 0;
                if (btn_r) begin
                    n_state = START;
                end
            end
            START: begin
                if (i_tick_1us) begin
                    if (trig_cnt_reg == 10) begin
                        trig_cnt_next = 0;
                        n_state = WAIT;
                    end else begin
                        trig_cnt_next = trig_cnt_reg + 1;
                    end
                end
            end
            WAIT: begin
                if (echo) begin
                    n_state = DISTANCE;
                end
            end
            DISTANCE: begin
                if (!echo) begin
                    n_state = IDLE;
                    distance_next = (echo_time_reg * 1131) >> 16; // 1/58 -> 0.0172, 0.0172 * 65536 한 뒤, 비트 shift >> 16
                    //distance_next = echo_time_reg / 58;
                end else begin
                    if (i_tick_1us) begin
                        echo_time_next = echo_time_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule
