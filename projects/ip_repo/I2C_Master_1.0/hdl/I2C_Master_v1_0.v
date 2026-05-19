
`timescale 1 ns / 1 ps

module I2C_Master_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    inout  wire sda,  // 추가됨
    output wire scl,  // 추가됨
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);
 
    // S00_AXI 래퍼와 I2C 마스터를 연결할 내부 배선들
    wire       w_cmd_start;
    wire       w_cmd_write;
    wire       w_cmd_read;
    wire       w_cmd_stop;
    wire       w_ack_in;
    wire [7:0] w_tx_data;

    wire       w_busy;
    wire       w_done;
    wire       w_ack_out;
    wire [7:0] w_rx_data;

    // Instantiation of Axi Bus Interface S00_AXI
    I2C_Master_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) I2C_Master_v1_0_S00_AXI_inst (
        // [추가] 위에서 선언한 와이어들을 연결
        .cmd_start_out(w_cmd_start),
        .cmd_write_out(w_cmd_write),
        .cmd_read_out (w_cmd_read),
        .cmd_stop_out (w_cmd_stop),
        .ack_in_out   (w_ack_in),
        .tx_data_out  (w_tx_data),
        .busy_in      (w_busy),
        .done_in      (w_done),
        .ack_out_in   (w_ack_out),
        .rx_data_in   (w_rx_data),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // Add user logic here
    I2C_Master u_i2c_core (
        .clk(s00_axi_aclk),
        .reset(~s00_axi_aresetn),  // AXI는 Active-Low, I2C 코어는 Active-High
        .cmd_start(w_cmd_start),
        .cmd_write(w_cmd_write),
        .cmd_read(w_cmd_read),
        .cmd_stop(w_cmd_stop),
        .tx_data(w_tx_data),
        .ack_in(w_ack_in),
        .rx_data(w_rx_data),
        .done(w_done),
        .busy(w_busy),
        .ack_out(w_ack_out),
        .sda(sda),  // 최상위 포트로 바로 연결
        .scl(scl)  // 최상위 포트로 바로 연결
    );
    // User logic ends
endmodule

`timescale 1ns / 1ps

module I2C_Master (
    input  wire       clk,
    input  wire       reset,
    // command port
    input  wire       cmd_start,
    input  wire       cmd_write,
    input  wire       cmd_read,
    input  wire       cmd_stop,
    input  wire [7:0] tx_data,
    input  wire       ack_in,
    // internal output
    output wire [7:0] rx_data,
    output wire       done,
    output wire       busy,
    output wire       ack_out,
    // external i2c port
    inout  wire       sda,
    output wire       scl
);

    wire sda_o, sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_master u_i2c_master (
        .clk       (clk),
        .reset     (reset),
        .cmd_start (cmd_start),
        .cmd_write (cmd_write),
        .cmd_read  (cmd_read),
        .cmd_stop  (cmd_stop),
        .tx_data   (tx_data),
        .ack_in    (ack_in),
        .rx_data   (rx_data),
        .done      (done),
        .busy      (busy),
        .ack_out   (ack_out),
        .sda_i     (sda_i),
        .sda_o     (sda_o),
        .scl       (scl)
    );
endmodule

module i2c_master (
    input  wire       clk,
    input  wire       reset,
    // command port
    input  wire       cmd_start,
    input  wire       cmd_write,
    input  wire       cmd_read,
    input  wire       cmd_stop,
    input  wire [7:0] tx_data,
    input  wire       ack_in,
    // internal output
    output reg  [7:0] rx_data,
    output reg        done,
    output wire       busy,
    output reg        ack_out,
    // external i2c port
    input  wire       sda_i,
    output wire       sda_o,
    output wire       scl
);

    // State Machine parameter definition
    localparam [2:0]
        IDLE     = 3'd0,
        START    = 3'd1,
        WAIT_CMD = 3'd2,
        DATA     = 3'd3,
        DATA_ACK = 3'd4,
        STOP     = 3'd5;
        
    reg [2:0] state;

    reg  [7:0] div_cnt;
    reg        qtr_tick;
    reg        scl_r;
    reg        sda_r;
    reg  [1:0] step;
    reg  [7:0] tx_shift_reg;
    reg  [7:0] rx_shift_reg;
    reg  [2:0] bit_cnt;
    reg        is_read;
    reg        ack_in_r;
    
    // synchronizer
    reg  [1:0] sda_sync;
    wire       sda_safe;

    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            div_cnt  <= 0;
            qtr_tick <= 1'b0;
        end else begin
            if (div_cnt == 250 - 1) begin  // scl : 100khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end
    
    // synchronizer
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_sync <= 2'b11;
        end else begin
            sda_sync <= {sda_sync[0], sda_i};
        end
    end
    assign sda_safe = sda_sync[1];
    
    //
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            step         <= 0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            is_read      <= 1'b0;
            ack_in_r     <= 1'b1;
            ack_out      <= 1'b1;
            rx_data      <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    if (cmd_start) begin
                        state <= START;
                        step  <= 0;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: step <= 2'd1;
                            2'd1: step <= 2'd2;
                            2'd2: step <= 2'd3;
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt      <= 0;
                        is_read      <= 1'b0;
                        state        <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 0;
                        bit_cnt      <= 0;
                        is_read      <= 1'b1;
                        state        <= DATA;
                        ack_in_r     <= ack_in;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end
                end
                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: step <= 2'd1;
                            2'd1: step <= 2'd2;
                            2'd2: begin
                                if (is_read) begin
                                    rx_shift_reg <= {
                                        rx_shift_reg[6:0], sda_safe
                                    };
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                if (!is_read) begin
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                step <= 2'd0;
                                if (bit_cnt == 7) begin
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: step <= 2'd1;
                            2'd1: step <= 2'd2;
                            2'd2: begin
                                if (!is_read) begin  // slv -> mst send ack
                                    ack_out <= sda_safe;
                                end
                                if (is_read) begin
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: step <= 2'd1;
                            2'd1: step <= 2'd2;
                            2'd2: step <= 2'd3;
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

    always @(*) begin
        sda_r = 1'b1;
        scl_r = 1'b1;
        case (state)
            IDLE: begin
                sda_r = 1'b1;
                scl_r = 1'b1;
            end
            START: begin
                if (step != 2'd0) sda_r = 1'b0;
                else sda_r = 1'b1;
                if (step == 2'd3) scl_r = 1'b0;
                else scl_r = 1'b1;
            end
            WAIT_CMD: begin
                sda_r = 1'b0;
                scl_r = 1'b0;
            end
            DATA: begin
                if (is_read) sda_r = 1'b1;
                else sda_r = tx_shift_reg[7];
                if (step == 2'd1 | step == 2'd2) scl_r = 1'b1;
                else scl_r = 1'b0;
            end
            DATA_ACK: begin
                if (is_read) sda_r = ack_in_r;
                else sda_r = 1'b1;  // sda input, high z setting
                if (step == 2'd1 | step == 2'd2) scl_r = 1'b1;
                else scl_r = 1'b0;
            end
            STOP: begin
                if (step == 2'd0 | step == 2'd1) sda_r = 1'b0;
                else sda_r = 1'b1;
                if (step == 2'd0) scl_r = 1'b0;
                else scl_r = 1'b1;
            end
        endcase
    end
endmodule