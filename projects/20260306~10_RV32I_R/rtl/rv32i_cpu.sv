`timescale 1ns / 1ps
`include "define.vh"

module rv32i_cpu (
    input         clk,
    input         rst,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    output [31:0] instr_addr,
    output        dwe,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic rf_we, alu_src_sel, rfwd_srcsel;
    logic [3:0] alu_control;

    control_unit U_CONTROL_UNIT (
        .funct7     (instr_data[31:25]),
        .funct3     (instr_data[14:12]),
        .opcode     (instr_data[6:0]),
        .rf_we      (rf_we),
        .alu_src_sel(alu_src_sel),
        .alu_control(alu_control),
        .rfwd_srcsel(rfwd_srcsel),
        .dwe        (dwe)
    );

    rv32i_datapath U_DATAPATH (.*);
endmodule

module control_unit (
    input        [6:0] funct7,
    input        [2:0] funct3,
    input        [6:0] opcode,
    output logic       rf_we,
    output logic       alu_src_sel,
    output logic [3:0] alu_control,
    output logic       rfwd_srcsel,
    output logic       dwe
);

    always_comb begin
        rf_we       = 1'b0;
        alu_src_sel = 1'b0;
        alu_control = 4'b0000;
        rfwd_srcsel = 1'b0;
        dwe         = 1'b0;
        case (opcode)
            // R-type, to write register file, alu_control == {funct7[5], funct3}
            `R_TYPE: begin
                rf_we       = 1'b1;
                alu_src_sel = 1'b0;
                alu_control = {funct7[5], funct3};
                rfwd_srcsel = 1'b0;
                dwe         = 1'b0;
            end
            `S_TYPE: begin
                rf_we       = 1'b0;
                alu_src_sel = 1'b1;
                alu_control = 4'b0000;
                rfwd_srcsel = 1'b0;
                dwe         = 1'b1;
            end
            `IL_TYPE: begin
                rf_we       = 1'b1;
                alu_src_sel = 1'b1;
                alu_control = 4'b0000;
                rfwd_srcsel = 1'b1;
                dwe         = 1'b0;
            end
        endcase
    end
endmodule
