`timescale 1ns / 1ps

module spi_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       cs_n,
    input  logic [7:0] tx_data,
    input  logic       mosi,
    output logic       miso,
    output logic [7:0] rx_data
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    spi_state_e       state;
    logic             half_tick;
    logic       [7:0] tx_shift_reg;
    logic       [7:0] rx_shift_reg;
    logic       [2:0] bit_cnt;
    logic             phase;
    logic             sclk_r;

    assign sclk = sclk_r;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            half_tick    <= 1'b0;
            miso         <= 1'b1;
            rx_data      <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            phase        <= 1'b0;
            sclk_r       <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    miso   <= 1'b1;
                    sclk_r <= 1'b0;
                end
                START: begin
                end
                DATA: begin
                end
                STOP: begin
                end
                default: begin
                end
            endcase


        end
    end


endmodule
