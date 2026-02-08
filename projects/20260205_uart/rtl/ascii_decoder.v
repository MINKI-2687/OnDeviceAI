`timescale 1ns / 1ps

module ascii_decoder (
    input            clk,
    input            rst,
    input      [7:0] rx_data,             // from uart_rx
    input            rx_done,             // rx complete signal
    // from uart input (r, l, u, d)
    output reg       uart_btn_r,          // run_stop
    output reg       uart_btn_l,          // clear
    output reg       uart_btn_u,          // up
    output reg       uart_btn_d,          // down
    // from uart input (sw[0], [1], [2])
    output reg       uart_sw_mode,
    output reg       uart_sw_sel_mode,
    output reg       uart_sw_sel_display
);

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            uart_btn_r       <= 1'b0;
            uart_btn_l       <= 1'b0;
            uart_btn_u       <= 1'b0;
            uart_btn_d       <= 1'b0;
            uart_sw_mode     <= 1'b0;
            uart_sw_sel_mode <= 1'b0;
            uart_sw_sel_mode <= 1'b0;
        end else begin
            uart_btn_r <= 1'b0;
            uart_btn_l <= 1'b0;
            uart_btn_u <= 1'b0;
            uart_btn_d <= 1'b0;
            if (rx_done) begin
                case (rx_data)
                    8'h72: uart_btn_r <= 1'b1;  // 'r' (run_stop)
                    8'h6C: uart_btn_l <= 1'b1;  // 'l' (clear)
                    8'h75: uart_btn_u <= 1'b1;  // 'u' (up)
                    8'h64: uart_btn_d <= 1'b1;  // 'd' (down)
                    8'h30:
                    uart_sw_mode <= ~uart_sw_mode;  // sw[0] (up/down mode)
                    8'h31:
                    uart_sw_sel_mode <= ~uart_sw_sel_mode;  // sw[1] sel_mode
                    8'h32:
                    uart_sw_sel_display <= ~uart_sw_sel_display;  // sw[2] (sel_display)
                endcase
            end
        end
    end

endmodule
