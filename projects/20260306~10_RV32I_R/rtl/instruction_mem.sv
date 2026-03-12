`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);
    // 명령어 저장을 위한 rom
    logic [31:0] rom[0:31];

    initial begin
        $readmemh("riscv_rv32i_rom_data.mem", rom);
        //// R-type
        //rom[0]  = 32'h0041_82b3;  // ADD x5, x3, x4
        //rom[1]  = 32'h4041_82b3;  // SUB x5, x3, x4
        //rom[2]  = 32'h4032_02b3;  // SUB x5, x4, x3
        //rom[3]  = 32'h0041_92b3;  // SLL x5, x3, x4
        //rom[4]  = 32'h0043_22b3;  // SLT x5, x6, x4
        //rom[5]  = 32'h0043_32b3;  // SLTU x5, x6, x4
        //rom[6]  = 32'h0041_c2b3;  // XOR x5, x3, x4
        //rom[7]  = 32'h0103_52b3;  // SRL x5, x6, x16
        //rom[8]  = 32'h4103_52b3;  // SRA x5, x6, x16
        //rom[9]  = 32'h0041_e2b3;  // OR x5, x3, x4
        //rom[10] = 32'h0041_f2b3;  // AND x5, x3, x4

        //// S-type
        //rom[0] = 32'h0081_2123;  // SW x2, x8, 2
        //// IL-type
        //rom[1] = 32'h0021_2383;  // LW x7, x2, 2
        //// I-type
        //rom[2] = 32'h0043_8413;  // ADDi x8, x7, 4
        //// B-type
        //rom[3] = 32'h0084_0463;  // BEQ x8, x8, 8
        //rom[4] = 32'h0041_82b3;  // ADD x5, x3, x4
        //rom[5] = 32'h0081_2123;  // SW x2, x8, 2
    end

    // [31:2] 로 시뮬레이션 시간을 단축?
    assign instr_data = rom[instr_addr[31:2]];

endmodule
