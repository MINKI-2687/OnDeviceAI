`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         alu_src_sel,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    output [31:0] instr_addr,
    output [31:0] dwaddr,
    output [31:0] dwdata
);

    logic [31:0] rd1, rd2, alu_result, imm_data, alurs2_data;

    assign dwaddr = alu_result;
    assign dwdata = rd2;

    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .program_counter(instr_addr)
    );

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .ra1  (instr_data[19:15]),
        .ra2  (instr_data[24:20]),
        .wa   (instr_data[11:7]),
        .wdata(alu_result),
        .rf_we(rf_we),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0      (rd2),          // sel 0
        .in1      (imm_data),     // sel 1
        .alusrcsel(alu_src_sel),
        .out_mux  (alurs2_data)
    );

    alu U_ALU (
        .rd1        (rd1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result)
    );
endmodule

module mux_2x1 (
    input        [31:0] in0,        // sel 0
    input        [31:0] in1,        // sel 1
    input               alusrcsel,
    output logic [31:0] out_mux
);

    assign out_mux = (alusrcsel) ? in1 : in0;
endmodule

module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `S_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
        endcase
    end
endmodule

module register_file (
    input         clk,
    input         rst,
    input  [ 4:0] ra1,    // instruction code RS1
    input  [ 4:0] ra2,    // instruction code RS2
    input  [ 4:0] wa,     // instruction code RD
    input  [31:0] wdata,  // instruction RD write data
    input         rf_we,  // Register File Write Enable
    output [31:0] rd1,    // Register File RS1 output
    output [31:0] rd2     // Register File RS2 output
);

    logic [31:0] register_file[0:31];

`ifdef SIMULATION
    initial begin
        for (int i = 0; i < 32; i++) begin
            register_file[i] = i;
        end
    end
`endif

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register_file[0] <= 32'h0;
        end else begin
            if (!rst & rf_we) begin
                if (wa != 0) register_file[wa] <= wdata;
            end
        end
    end

    // output CL
    assign rd1 = (ra1 != 0) ? register_file[ra1] : 0;
    assign rd2 = (ra2 != 0) ? register_file[ra2] : 0;
endmodule

module alu (
    input        [31:0] rd1,          // RS1 (unsigned)
    input        [31:0] rd2,          // RS2 (unsigned)
    input        [ 3:0] alu_control,  // func7[6], func3 : 4bit
    output logic [31:0] alu_result
);

    always_comb begin
        alu_result = 0;
        case (alu_control)
            // ADD RD = RS1 + RS2
            `ADD:  alu_result = rd1 + rd2;
            // SUB RD = RS1 - RS2
            `SUB:  alu_result = rd1 - rd2;
            // SLL RD = RS1 << RS2
            `SLL:  alu_result = rd1 << rd2[4:0];
            // SLT RD = (RS1 < RS2) ? 1 : 0 (signed)
            `SLT:  alu_result = ($signed(rd1) < $signed(rd2)) ? 1 : 0;
            // SLTU RD = (RS1 < RS2) ? 1 : 0 (unsigned)
            `SLTU: alu_result = (rd1 < rd2) ? 1 : 0;
            // XOR RD = RS1 ^ RS2
            `XOR:  alu_result = rd1 ^ rd2;
            // SRL RD = RS1 >> RS2
            `SRL:  alu_result = rd1 >> rd2[4:0];
            // SRA RD = RS1 >> RS2 (msb extention, arithmetic right shift)
            `SRA:  alu_result = $signed(rd1) >>> rd2[4:0];
            // OR RD = RS1 | RS2
            `OR:   alu_result = rd1 | rd2;
            // AND RD = RS1 & RS2
            `AND:  alu_result = rd1 & rd2;
        endcase
    end
endmodule

module program_counter (
    input         clk,
    input         rst,
    output [31:0] program_counter
);
    logic [31:0] pc_alu_out;

    pc_alu U_PC_ALU_4 (
        .a         (32'd4),
        .b         (program_counter),
        .pc_alu_out(pc_alu_out)
    );

    register U_PC_REG (
        .clk     (clk),
        .rst     (rst),
        .data_in (pc_alu_out),
        .data_out(program_counter)
    );
endmodule

module pc_alu (
    input  [31:0] a,
    input  [31:0] b,
    output [31:0] pc_alu_out
);

    assign pc_alu_out = a + b;
endmodule

module register (
    input         clk,
    input         rst,
    input  [31:0] data_in,
    output [31:0] data_out
);

    logic [31:0] register;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            register <= 0;
        end else begin
            register <= data_in;
        end
    end

    assign data_out = register;
endmodule

