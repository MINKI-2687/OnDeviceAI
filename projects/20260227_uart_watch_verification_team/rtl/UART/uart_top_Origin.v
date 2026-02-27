`timescale 1ns / 1ps
module uart_top (
    input        clk,
    input        reset,
    //input        btn_down,
    input        uart_rx,
    output       uart_tx
);

    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data;
   //버튼으로 입력
   //btn_debounce U_BD_TX_START (
   //    .clk  (clk),
   //    .reset(reset),
   //    .i_btn(btn_down),
   //    .o_btn(w_tx_start)
   // );

    // btn 송신기(Tx)
    uart_tx U_UART_TX (
        .clk     (clk),
        .reset   (reset),
        .tx_start(w_rx_done),
        .b_tick  (w_b_tick),
        .tx_data (w_rx_data),
        .tx_busy (),
        .tx_done (),
        .uart_tx (uart_tx)
    );

    //btn 수신기(rx)
    uart_rx U_UART_RX (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

    // 비동기이므로 CLK 없음
    // 그래서 동기 신호를 생성(CLK 아님)
    baud_tick U_BAUD_TICK (
        .clk   (clk),
        .reset (reset),
        .b_tick(w_b_tick)
    );
endmodule

module uart_rx (
    input        clk,
    input        reset,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);
    localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
    reg [1:0] c_state, n_state;
    
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    
    reg [2:0] bit_cnt_next, bit_cnt_reg;
    
    reg done_reg, done_next;
    //buffer
    reg [7:0] buf_reg, buf_next;

    assign rx_data = buf_reg;
    assign rx_done = done_reg; 

    // state register 
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state        <= 2'd0;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    //next output(CL)
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                b_tick_cnt_next = 5'b0;
                bit_cnt_next    = 3'd0;
                done_next       = 1'b0;
                if (b_tick * !rx) begin
                    buf_next    = 8'd0; // 변경 점 
                    n_state = START;
                end
            end
            START: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 7) begin // 바뀐부분
                        b_tick_cnt_next = 5'd0; 
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd15) begin
                        b_tick_cnt_next = 5'd0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 16) begin // 변경점
                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
        endcase
    end
endmodule


module uart_tx (
    input       clk,
    input       reset,
    input       tx_start,
    input       b_tick,
    input [7:0] tx_data,

    output tx_busy,
    output tx_done,
    output uart_tx

);
    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    //state reg ; c:current n: next
    reg [1:0] c_state, n_state;
    //for output SL
    reg tx_reg, tx_next;
    //bit_cnt
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    //baud tick counter
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    //busy,done
    reg busy_reg, busy_next, done_reg, done_next;
    //data_in_buf
    // 보호논리임. 이걸 뺴놓고 하면 나중에 문제 생길수있음. 
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    //state register SL
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            b_tick_cnt_reg  <= 4'h0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            busy_reg        <= busy_next;
            done_reg        <= done_next;
            data_in_buf_reg <= data_in_buf_next;
        end
    end

    //next CL 
    always @(*) begin
        n_state          = c_state;
        tx_next          = tx_reg;  // full case
        bit_cnt_next     = bit_cnt_reg;
        b_tick_cnt_next  = b_tick_cnt_reg;
        busy_next        = busy_reg;
        done_next        = done_reg;
        data_in_buf_next = data_in_buf_reg;
        case (c_state)
            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 1'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 1'b0;
                done_next       = 1'b0;
                if (tx_start == 1) begin
                    n_state          = START;
                    busy_next        = 1'b1;
                    //start가 인지했을때 안전하게 가자 
                    data_in_buf_next = tx_data;
                end
            end
            START: begin
                //start uart frame start bit
                tx_next = 1'b0;
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            // wait 나중에 없앨 것. 지금은 못없앰. start 들어가면서 내부의 8비트짜리 버퍼 잡고 들어오는 데이터 카피해놓고 카피해놓은걸 출력. 
            // 그럼 start 조건에서만 카피하니까 문제 없다. 
            // next_start 가라고 할때 
            //----------------------------------------------------------------------------------------------//
            DATA: begin
                tx_next = data_in_buf_reg[0];
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 4'h0;
                            n_state = STOP;
                        end else begin
                            b_tick_cnt_next = 4'h0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                            n_state = DATA;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                //done_next =1'b1; 이거는 문제 한 구간 동안생겨버림
                if (b_tick == 1) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        n_state   = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end
endmodule


// 9600 bps => 9600 (bits) Hz 의 주기로 보내야 
// 즉 9600 Hz의 신호를 생성해야 함: baud_tick
// 시스템 클락 주파수 / 목표의 주파수 =  목표의 한 주기 시간 / 시스템의 한 주기 시간  =  필요한 카운트 수 

// clk = 100MHz = > 1 cycle 10ns 
//baud_tick; 주기 1/9600 초  , 9600 [bps]  ; bit per second 
module baud_tick (
    input      clk,
    input      reset,
    output reg b_tick
);

    parameter BAUDRATE = 9600 * 16;
    parameter F_COUNT = 100_000_000 / BAUDRATE;

    //reg for counter 
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            b_tick      <= 1'b0;
        end else begin
            // Counter  
            counter_reg <= counter_reg + 1;
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                b_tick <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end
endmodule
