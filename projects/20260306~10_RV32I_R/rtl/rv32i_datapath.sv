`timescale 1ns / 1ps
`include "define.vh"

module rv32i_datapath (
    input         clk,
    input         rst,
    input         rf_we,
    input         branch,
    input         jal,
    input         jalr,
    input         alu_src_sel,
    input  [ 3:0] alu_control,
    input  [31:0] instr_data,
    input  [31:0] drdata,
    input  [ 2:0] rfwd_srcsel,
    output [31:0] instr_addr,
    output [31:0] daddr,
    output [31:0] dwdata
);

    logic [31:0]
        rd1, rd2, alu_result, imm_data, alurs2_data, rfwb_data, auipc, j_type;
    logic btaken;

    assign daddr  = alu_result;
    assign dwdata = rd2;

    program_counter U_PC (
        .clk            (clk),
        .rst            (rst),
        .btaken         (btaken),     // from alu comparator
        .branch         (branch),     // from control unit for B-type
        .jal            (jal),
        .jalr           (jalr),
        .rd1            (rd1),
        .imm_data       (imm_data),
        .pc_imm_out     (auipc),
        .pc_4_out       (j_type),
        .program_counter(instr_addr)
    );

    register_file U_REG_FILE (
        .clk  (clk),
        .rst  (rst),
        .ra1  (instr_data[19:15]),
        .ra2  (instr_data[24:20]),
        .wa   (instr_data[11:7]),
        .wdata(rfwb_data),
        .rf_we(rf_we),
        .rd1  (rd1),
        .rd2  (rd2)
    );

    imm_extender U_IMM_EXTEND (
        .instr_data(instr_data),
        .imm_data  (imm_data)
    );

    mux_2x1 U_MUX_ALUSRC_RS2 (
        .in0    (rd2),          // sel 0
        .in1    (imm_data),     // sel 1
        .mux_sel(alu_src_sel),
        .out_mux(alurs2_data)
    );

    alu U_ALU (
        .rd1        (rd1),
        .rd2        (alurs2_data),
        .alu_control(alu_control),
        .alu_result (alu_result),
        .btaken     (btaken)
    );

    // to register file
    mux_5x1 U_MUX_WB_REGFILE (
        .in0    (alu_result),   // alu result
        .in1    (drdata),       // from data memory
        .in2    (imm_data),     // from imm extend, LUI
        .in3    (auipc),        // from pc + imm extend, AUIPC
        .in4    (j_type),       // from pc + 4, JAL, JALR
        .mux_sel(rfwd_srcsel),
        .out_mux(rfwb_data)
    );

endmodule

module mux_2x1 (
    input        [31:0] in0,      // sel 0
    input        [31:0] in1,      // sel 1
    input               mux_sel,
    output logic [31:0] out_mux
);

    assign out_mux = (mux_sel) ? in1 : in0;
endmodule

module imm_extender (
    input        [31:0] instr_data,
    output logic [31:0] imm_data
);

    always_comb begin
        imm_data = 32'd0;
        case (instr_data[6:0])
            `B_TYPE: begin
                imm_data = {
                    {20{instr_data[31]}},  // imm[31:12]
                    instr_data[7],  // imm[11]
                    instr_data[30:25],  // imm[10:5]
                    instr_data[11:8],  // imm[4:1]
                    1'b0  // imm[0]
                };
            end
            `S_TYPE: begin  // store
                imm_data = {
                    {20{instr_data[31]}}, instr_data[31:25], instr_data[11:7]
                };
            end
            `I_TYPE, `IL_TYPE, `JL_TYPE: begin  // load, JALR
                imm_data = {{20{instr_data[31]}}, instr_data[31:20]};
            end
            `U_TYPE, `UPC_TYPE: begin
                imm_data = {instr_data[31:12], 12'b0};
            end
            `J_TYPE: begin
                imm_data = {
                    {12{instr_data[31]}},  // imm[31:20]
                    instr_data[19:12],  //  imm[19:12]
                    instr_data[20],  // imm[11]
                    instr_data[30:21],  // imm[10:1]
                    1'b0  // imm[0]
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
        register_file[6] = 32'hFFFF_0000;
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
    output logic [31:0] alu_result,
    output logic        btaken
);
    // shared alu
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

    // B-type comparator
    // btaken 신호를 통해 control_unit의 branch와 AND 연산
    always_comb begin
        btaken = 0;
        case (alu_control)
            `BEQ: begin
                if (rd1 == rd2) btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
            `BNE: begin
                if (rd1 != rd2) btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
            `BLT: begin
                if ($signed(rd1) < $signed(rd2))
                    btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
            `BGE: begin
                if ($signed(rd1) >= $signed(rd2))
                    btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
            `BLTU: begin
                if (rd1 < rd2) btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
            `BGEU: begin
                if (rd1 >= rd2) btaken = 1;  // true : pc += imm
                else btaken = 0;  // false : pc += 4
            end
        endcase
    end
endmodule

module mux_5x1 (
    input        [31:0] in0,
    input        [31:0] in1,
    input        [31:0] in2,
    input        [31:0] in3,
    input        [31:0] in4,
    input        [ 2:0] mux_sel,
    output logic [31:0] out_mux
);
    always_comb begin
        case (mux_sel)
            3'd0: out_mux = in0;
            3'd1: out_mux = in1;
            3'd2: out_mux = in2;
            3'd3: out_mux = in3;
            3'd4: out_mux = in4;
            default: out_mux = 32'hxxxx;
        endcase
    end
endmodule

module program_counter (
    input         clk,
    input         rst,
    input         btaken,          // from alu for B-type
    input         branch,          // from control unit for B-type
    input         jal,
    input         jalr,
    input  [31:0] rd1,
    input  [31:0] imm_data,
    output [31:0] pc_imm_out,      // for UPC type (pc + imm)
    output [31:0] pc_4_out,        // for J, JL type (pc + 4)
    output [31:0] program_counter
);
    logic [31:0] pc_next, pc_jtype;

    // jalr mux
    mux_2x1 U_PC_JTYPE_MUX (
        .in0    (program_counter),  // sel 0
        .in1    (rd1),              // sel 1
        .mux_sel(jalr),
        .out_mux(pc_jtype)
    );

    pc_alu U_PC_IMM (
        .a         (imm_data),
        .b         (pc_jtype),
        .pc_alu_out(pc_imm_out)
    );

    pc_alu U_PC_4 (
        .a         (32'd4),
        .b         (program_counter),
        .pc_alu_out(pc_4_out)
    );

    mux_2x1 U_PC_NEXT_MUX (
        .in0    (pc_4_out),                 // sel 0
        .in1    (pc_imm_out),               // sel 1
        .mux_sel(jal | (btaken & branch)),
        .out_mux(pc_next)
    );

    register U_PC_REG (
        .clk     (clk),
        .rst     (rst),
        .data_in (pc_next),
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

