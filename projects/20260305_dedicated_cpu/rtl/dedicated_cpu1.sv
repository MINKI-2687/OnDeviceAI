`timescale 1ns / 1ps

module dedicated_cpu1 (
    input        clk,
    input        rst,
    output [7:0] out
);

    logic asrcsel, aload, sumsrcsel, sumload, alusrcsel, outload, alt11;

    control_unit1 U_CONTROL_UNIT (.*);
    datapath1 U_DATAPATH (.*);
endmodule
//
module control_unit1 (
    input        clk,
    input        rst,
    input        alt11,
    output logic asrcsel,
    output logic aload,
    output logic sumsrcsel,
    output logic sumload,
    output logic alusrcsel,
    output logic outload
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5
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
        n_state   = c_state;
        asrcsel   = 0;
        aload     = 0;
        sumsrcsel = 0;
        sumload   = 0;
        alusrcsel = 0;
        outload   = 0;
        case (c_state)
            S0: begin
                asrcsel   = 0;
                aload     = 1;
                sumsrcsel = 0;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = S1;
            end
            S1: begin
                asrcsel   = 0;
                aload     = 0;
                sumsrcsel = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                if (alt11) begin
                    n_state = S2;
                end else begin
                    n_state = S5;
                end
            end
            S2: begin
                asrcsel   = 0;
                aload     = 0;
                sumsrcsel = 1;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = S3;
            end
            S3: begin
                asrcsel   = 1;
                aload     = 1;
                sumsrcsel = 0;
                sumload   = 0;
                alusrcsel = 1;
                outload   = 0;
                n_state   = S4;
            end
            S4: begin
                asrcsel   = 0;
                aload     = 0;
                sumsrcsel = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 1;
                n_state   = S1;
            end
            S5: begin
                aload     = 0;
                sumsrcsel = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                n_state   = S5;
            end
        endcase
    end
endmodule
//
module datapath1 (
    input        clk,
    input        rst,
    input        asrcsel,
    input        aload,
    input        sumsrcsel,
    input        sumload,
    input        alusrcsel,
    input        outload,
    output       alt11,
    output [7:0] out
);

    logic [7:0]
        areg_src_data,
        sumreg_src_data,
        areg_out,
        sumreg_out,
        alu_src_data,
        alu_out;

    register1 U_OUTREG (
        .clk     (clk),
        .rst     (rst),
        .load    (outload),
        .in_data (sumreg_out),
        .out_data(out)
    );

    mux1_2x1 U_AREG_SRC_MUX (
        .a      (8'h00),
        .b      (alu_out),
        .sel    (asrcsel),
        .mux_out(areg_src_data)
    );

    register1 U_AREG (
        .clk     (clk),
        .rst     (rst),
        .load    (aload),
        .in_data (areg_src_data),
        .out_data(areg_out)
    );

    mux1_2x1 U_SUMREG_SRC_MUX (
        .a      (8'h00),
        .b      (alu_out),
        .sel    (sumsrcsel),
        .mux_out(sumreg_src_data)
    );

    register1 U_SUMREG (
        .clk     (clk),
        .rst     (rst),
        .load    (sumload),
        .in_data (sumreg_src_data),
        .out_data(sumreg_out)
    );

    mux1_2x1 U_ALU_SRC_MUX (
        .a      (sumreg_out),
        .b      (1),
        .sel    (alusrcsel),
        .mux_out(alu_src_data)
    );

    alu1 U_ALU (
        .a      (areg_out),      // from areg
        .b      (alu_src_data),  // from sumreg
        .alu_out(alu_out)
    );

    alt11_comp1 U_ALT11 (
        .in_data(areg_out),
        .alt11  (alt11)
    );
endmodule
//
module register1 (
    input              clk,
    input              rst,
    input              load,
    input        [7:0] in_data,
    output logic [7:0] out_data
);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_data <= 0;
        end else begin
            if (load) out_data <= in_data;
        end
    end
endmodule
//
module alu1 (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);

    assign alu_out = a + b;
endmodule
//
module mux1_2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);

    assign mux_out = (sel) ? b : a;
endmodule
//
module alt11_comp1 (
    input  [7:0] in_data,
    output       alt11
);

    assign alt11 = (in_data < 11);
endmodule
