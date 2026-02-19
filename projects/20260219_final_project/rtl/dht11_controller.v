`timescale 1ns / 1ps

module dht11_controller (
    input         clk,
    input         rst,
    input         start,
    output [15:0] humidity,
    output [15:0] temperature,
    output        dht11_done,
    output        dht11_valid,
    output [ 2:0] debug,
    inout         dhtio
);

    wire tick_10u;

    tick_gen_10u U_TICK_10u (
        .clk     (clk),
        .rst     (rst),
        .tick_10u(tick_10u)
    );

    // STATE
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4;
    parameter DATA_SYNC = 5, DATA_C = 6, STOP = 7;

    reg [2:0] c_state, n_state;
    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;
    reg [39:0] data_reg, data_next;
    reg [5:0] bit_cnt_reg, bit_cnt_next;
    reg dhtio_sync_1, dhtio_sync_2;

    // for 19msec count by 10usec tick
    reg [$clog2(1900)-1:0] tick_cnt_reg, tick_cnt_next;

    assign dhtio = (io_sel_reg) ? dhtio_reg : 1'bz;
    assign debug = c_state;

    // checksum
    wire [7:0] checksum = data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8];

    assign humidity    = data_reg[39:24];
    assign temperature = data_reg[23:8];
    assign dht11_valid = (checksum == data_reg[7:0]) && (data_reg != 0);
    assign dht11_done  = (c_state == STOP);


    // dhtio synchronizer
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dhtio_sync_1 <= 1'b1;
            dhtio_sync_2 <= 1'b1;
        end else begin
            dhtio_sync_1 <= dhtio;
            dhtio_sync_2 <= dhtio_sync_1;
        end
    end

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 3'b000;
            dhtio_reg    <= 1'b1;
            tick_cnt_reg <= 1'b0;
            io_sel_reg   <= 1'b1;
            data_reg     <= 0;
            bit_cnt_reg  <= 0;
        end else begin
            c_state      <= n_state;
            dhtio_reg    <= dhtio_next;
            tick_cnt_reg <= tick_cnt_next;
            io_sel_reg   <= io_sel_next;
            data_reg     <= data_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    // next, output 
    always @(*) begin
        n_state       = c_state;
        tick_cnt_next = tick_cnt_reg;
        dhtio_next    = dhtio_reg;
        io_sel_next   = io_sel_reg;
        data_next     = data_reg;
        bit_cnt_next  = bit_cnt_reg;
        case (c_state)
            IDLE: begin
                if (start) begin
                    dhtio_next    = 1'b1;
                    io_sel_next   = 1'b1;
                    tick_cnt_next = 0;
                    bit_cnt_next  = 0;
                    n_state       = START;
                end
            end
            START: begin
                dhtio_next = 1'b0;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 1899) begin
                        tick_cnt_next = 0;
                        n_state = WAIT;
                    end
                end
            end
            WAIT: begin
                dhtio_next = 1'b1;
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 3) begin // 30us는 유지해줘야 다음 상태로 넘어감
                        tick_cnt_next = 0;
                        n_state = SYNC_L;
                        // for output to high-z
                        io_sel_next = 1'b0;
                    end
                end
            end
            // 센서 데이터 읽기 구간
            SYNC_L: begin
                if (tick_10u) begin
                    if (dhtio_sync_2 == 1) begin // edge detect 하는 방법도 있음
                        n_state = SYNC_H;
                    end
                end
            end
            // dhtio만 보는 거라 50us 뒤에 1로 뜨는 경우가 아닐 때도 있음.
            // 이걸 해결해봐라 (synchronizer 같은 거 쓰기)
            SYNC_H: begin
                if (tick_10u) begin
                    if (dhtio_sync_2 == 0) begin
                        n_state = DATA_SYNC;
                    end
                end
            end
            DATA_SYNC: begin
                if (tick_10u) begin
                    if (dhtio_sync_2 == 1) begin
                        n_state = DATA_C;
                    end
                end
            end
            DATA_C: begin
                if (tick_10u) begin
                    if (dhtio_sync_2 == 1) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    end else begin
                        // data
                        if (tick_cnt_reg > 4) begin  // high '1'
                            data_next = {data_reg[38:0], 1'b1};
                        end else begin
                            data_next = {data_reg[38:0], 1'b0};  // low '0'
                        end
                        tick_cnt_next = 0;

                        if (bit_cnt_reg == 39) begin  // 40 bit
                            bit_cnt_next = 0;
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state      = DATA_SYNC;  // next bit
                        end
                    end
                end
            end
            STOP: begin
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 5) begin
                        // output mode
                        dhtio_next  = 1'b1;
                        io_sel_next = 1'b1;
                        n_state     = IDLE;
                    end
                end
            end
        endcase
    end

endmodule

module tick_gen_10u (
    input      clk,
    input      rst,
    output reg tick_10u
);

    parameter F_COUNT = 100_000_000 / 100_000;

    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_10u    <= 1'b0;
        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_10u    <= 1'b1;
            end else begin
                tick_10u <= 1'b0;
            end
        end
    end

endmodule
