`timescale 1ns / 1ps

module uart_top (
    input  clk,
    input  rst,
    input  btn_down,
    output uart_tx
);

    wire w_b_tick, w_tx_start;

    btn_debounce U_BD_TX_START (
        .clk  (clk),
        .reset(rst),
        .i_btn(btn_down),
        .o_btn(w_tx_start)
    );

    uart_tx U_UART_TX (
        .clk     (clk),
        .rst     (rst),
        .tx_start(w_tx_start),
        .b_tick  (w_b_tick),
        .tx_data (8'h30),
        .tx_busy (),
        .tx_done (),
        .uart_tx (uart_tx)
    );

    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .rst   (rst),
        .b_tick(w_b_tick)
    );

endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       tx_busy,
    output       tx_done,
    output       uart_tx
);

    localparam IDLE = 3'd0, WAIT = 3'd1, START = 3'd2;
    localparam DATA = 3'd3, STOP = 3'd4;

    // state reg
    reg [2:0] c_state, n_state;
    reg tx_reg, tx_next;  // for SL output

    // bit_cnt
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    // tick_cnt
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    // busy, done
    reg busy_reg, busy_next, done_reg, done_next;

    // data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    // connect output, reg type /
    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
            b_tick_cnt_reg  <= 0;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
        end
    end

    // next CL
    always @(*) begin
        // latch issue
        n_state          = c_state;
        tx_next          = tx_reg;
        bit_cnt_next     = bit_cnt_reg;
        busy_next        = busy_reg;
        done_next        = done_reg;
        data_in_buf_next = data_in_buf_reg;
        b_tick_cnt_next  = b_tick_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 1'b0;
                busy_next       = 1'b0;
                done_next       = 1'b0;
                b_tick_cnt_next = 0;
                if (tx_start) begin
                    n_state          = WAIT;
                    busy_next        = 1'b1;
                    data_in_buf_next = tx_data;
                end
            end
            WAIT: begin
                if (b_tick) begin
                    n_state = START;
                    b_tick_cnt_next = 0;
                end
            end
            // to start uart frame of start bit
            START: begin
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = data_in_buf_reg[bit_cnt_reg];
                if (b_tick) begin
                    b_tick_cnt_next = b_tick_cnt_reg + 1;
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state = DATA;
                        end
                    end
                end
            end
            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    b_tick_cnt_next = b_tick_cnt_reg + 1;
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                    end
                end
            end
        endcase
    end

endmodule

module baud_tick (
    input      clk,
    input      rst,
    output reg b_tick
);

    parameter BAUDRATE = 9600 * 16;
    parameter F_COUNT = 100_000_000 / BAUDRATE;

    // reg for counter
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                b_tick      <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end

endmodule
