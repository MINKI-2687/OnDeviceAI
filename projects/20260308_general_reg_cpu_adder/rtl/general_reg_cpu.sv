`timescale 1ns / 1ps

module general_reg_cpu (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic we, rfsrcsel, ile10;
    logic [1:0] raddr0, raddr1, waddr;

    control_unit U_CONTROL_UNIT (.*);
    datapath U_DATAPATH (.*);
endmodule
//
module control_unit (
    input              clk,
    input              rst,
    input              ile10,
    output logic       we,
    output logic       rfsrcsel,
    output logic [1:0] raddr0,
    output logic [1:0] raddr1,
    output logic [1:0] waddr
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7
    } state_t;
    state_t c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end

    always_comb begin
        n_state  = c_state;
        rfsrcsel = 0;
        raddr0   = 0;
        raddr1   = 0;
        waddr    = 0;
        we       = 0;
        case (c_state)
            S0: begin
                rfsrcsel = 0;
                raddr0   = 0;
                raddr1   = 0;
                waddr    = 3;
                we       = 1;
                n_state  = S1;
            end
            S1: begin
                rfsrcsel = 1;
                raddr0   = 0;
                raddr1   = 0;
                waddr    = 1;
                we       = 1;
                n_state  = S2;
            end
            S2: begin
                rfsrcsel = 1;
                raddr0   = 0;
                raddr1   = 0;
                waddr    = 2;
                we       = 1;
                n_state  = S3;
            end
            S3: begin
                rfsrcsel = 0;
                raddr0   = 1;
                raddr1   = 0;
                waddr    = 0;
                we       = 0;
                if (ile10) begin
                    n_state = S4;
                end else begin
                    n_state = S6;
                end
            end
            S4: begin
                rfsrcsel = 1;
                raddr0   = 1;
                raddr1   = 2;
                waddr    = 2;
                we       = 1;
                n_state  = S5;
            end
            S5: begin
                rfsrcsel = 1;
                raddr0   = 1;
                raddr1   = 3;
                waddr    = 1;
                we       = 1;
                n_state  = S3;
            end
            S6: begin
                rfsrcsel = 0;
                raddr0   = 2;
                raddr1   = 0;
                waddr    = 0;
                we       = 0;
                n_state  = S7;
            end
            S7: begin
                rfsrcsel = 0;
                raddr0   = 0;
                raddr1   = 0;
                waddr    = 0;
                we       = 0;
                n_state  = S7;
            end
        endcase
    end
endmodule
//
module datapath (
    input        clk,
    input        rst,
    input        we,
    input        rfsrcsel,
    input  [1:0] raddr0,
    input  [1:0] raddr1,
    input  [1:0] waddr,
    output       ile10,
    output [7:0] out
);

    logic [7:0] rd0_out, rd1_out, alu_out, rf_src_data;

    assign out = rd0_out;

    register U_REGISTER (
        .clk(clk),
        .rst(rst),
        .we (we),
        .ra0(raddr0),
        .ra1(raddr1),
        .wa (waddr),
        .wd (rf_src_data),
        .rd0(rd0_out),
        .rd1(rd1_out)
    );

    alu U_ALU (
        .a      (rd0_out),
        .b      (rd1_out),
        .alu_out(alu_out)
    );

    mux_2x1 U_MUX (
        .a      (8'h01),
        .b      (alu_out),
        .sel    (rfsrcsel),
        .mux_out(rf_src_data)
    );

    ile10 U_ILE10 (
        .in_data(rd0_out),
        .ile10  (ile10)
    );
endmodule
//
module register (
    input              clk,
    input              rst,
    input              we,
    input        [1:0] ra0,
    input        [1:0] ra1,
    input        [1:0] wa,
    input        [7:0] wd,
    output logic [7:0] rd0,
    output logic [7:0] rd1
);

    // 1. 8비트 방이 4개 있는 배열 선언
    logic [7:0] register_file[0:3];

    // 2. 쓰기 동작 SL
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register_file[0] <= 0;
            register_file[1] <= 0;
            register_file[2] <= 0;
            register_file[3] <= 0;
        end else begin
            if (we) begin
                if (wa != 0) register_file[wa] <= wd;
            end
        end
    end

    // 3. 읽기 동작 CL (바로 출력)
    assign rd0 = (ra0 == 0) ? 8'b0 : register_file[ra0];
    assign rd1 = (ra1 == 0) ? 8'b0 : register_file[ra1];
endmodule
//
module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);

    assign alu_out = a + b;
endmodule
//
module mux_2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);

    assign mux_out = (sel) ? b : a;
endmodule
//
module ile10 (
    input  [7:0] in_data,
    output       ile10
);

    assign ile10 = (in_data <= 10);
endmodule
