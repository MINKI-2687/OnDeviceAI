/*`timescale 1ns / 1ps

module ascii_decoder (
    input        clk,
    input        rst,
    input  [7:0] rx_data,
    input        rx_done,
    // from uart input (r, l, u, d)
    output       uart_btn_r,          // run_stop
    output       uart_btn_l,          // clear
    output       uart_btn_u,          // up
    output       uart_btn_d,          // down
    // from uart input (sw[0], [1], [2])
    output       uart_sw_mode,
    output       uart_sw_sel_mode,
    output       uart_sw_sel_display
);

    parameter IDLE = 1'b0, DECODE = 1'b1;

    reg c_state, n_state;
    reg btn_r_reg, btn_r_next;
    reg btn_l_reg, btn_l_next;
    reg btn_u_reg, btn_u_next;
    reg btn_d_reg, btn_d_next;
    reg sw_mode_reg, sw_mode_next;
    reg sw_sel_mode_reg, sw_sel_mode_next;
    reg sw_sel_display_reg, sw_sel_display_next;

    assign uart_btn_r = btn_r_reg;
    assign uart_btn_l = btn_l_reg;
    assign uart_btn_u = btn_u_reg;
    assign uart_btn_d = btn_d_reg;
    assign uart_sw_mode = sw_mode_reg;
    assign uart_sw_sel_mode = sw_sel_mode_reg;
    assign uart_sw_sel_display = sw_sel_display_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state            <= IDLE;
            btn_r_reg          <= 1'b0;
            btn_l_reg          <= 1'b0;
            btn_u_reg          <= 1'b0;
            btn_d_reg          <= 1'b0;
            sw_mode_reg        <= 1'b0;
            sw_sel_mode_reg    <= 1'b0;
            sw_sel_display_reg <= 1'b0;
        end else begin
            c_state            <= n_state;
            btn_r_reg          <= btn_r_next;
            btn_l_reg          <= btn_l_next;
            btn_u_reg          <= btn_u_next;
            btn_d_reg          <= btn_d_next;
            sw_mode_reg        <= sw_mode_next;
            sw_sel_mode_reg    <= sw_sel_mode_next;
            sw_sel_display_reg <= sw_sel_display_next;
        end
    end

    always @(*) begin
        n_state             = c_state;
        btn_r_next          = 1'b0;
        btn_l_next          = 1'b0;
        btn_u_next          = 1'b0;
        btn_d_next          = 1'b0;
        sw_mode_next        = sw_mode_reg;
        sw_sel_mode_next    = sw_sel_mode_reg;
        sw_sel_display_next = sw_sel_display_reg;
        case (c_state)
            IDLE: begin
                if (rx_done) begin
                    n_state = DECODE;
                end
            end
            DECODE: begin
                case (rx_data)
                    8'h72: btn_r_next = 1'b1;  // 'r' (run_stop)
                    8'h6C: btn_l_next = 1'b1;  // 'l' (clear)
                    8'h75: btn_u_next = 1'b1;  // 'u' (up)
                    8'h64: btn_d_next = 1'b1;  // 'd' (down)
                    8'h30:
                    sw_mode_next = ~sw_mode_reg;  // sw[0] (up/down mode)
                    8'h31:
                    sw_sel_mode_next = ~sw_sel_mode_reg;  // sw[1] sel_mode
                    8'h32:
                    sw_sel_display_next = ~sw_sel_display_reg;  // sw[2] (sel_display)
                endcase
                n_state = IDLE;
            end
        endcase
    end
endmodule*/

`timescale 1ns / 1ps

module ascii_decoder (
    input        clk,
    input        rst,
    input  [7:0] rx_data,
    input        rx_done,
    // from uart input (r, l, u, d)
    output       uart_btn_r,          // run_stop
    output       uart_btn_l,          // clear
    output       uart_btn_u,          // up
    output       uart_btn_d,          // down
    // from uart input (sw[0], [1], [2])
    output       uart_sw_mode,
    output       uart_sw_sel_mode,
    output       uart_sw_sel_display
);
    // 1. 버튼 로직 (rx_done이 1일 때만 유효함)
    assign uart_btn_r          = (rx_done && (rx_data == 8'h72));  // 'r'
    assign uart_btn_l          = (rx_done && (rx_data == 8'h6C));  // 'l'
    assign uart_btn_u          = (rx_done && (rx_data == 8'h75));  // 'u'
    assign uart_btn_d          = (rx_done && (rx_data == 8'h64));  // 'd'

    // 2. 스위치 로직 (조합 회로에서는 '상태 저장'이 불가능함)
    assign uart_sw_mode        = (rx_done && (rx_data == 8'h30));  // '0'
    assign uart_sw_sel_mode    = (rx_done && (rx_data == 8'h31));  // '1'
    assign uart_sw_sel_display = (rx_done && (rx_data == 8'h32));  // '2'

>>>>>>> d2ee0554d109c16b0e57a013a8a23dfe10273b19
endmodule
