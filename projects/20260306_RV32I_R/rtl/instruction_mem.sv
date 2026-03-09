`timescale 1ns / 1ps

module instruction_mem (
    input  [31:0] instr_addr,
    output [31:0] instr_data
);
    // 명령어 저장을 위한 rom
    logic [31:0] rom[0:31];

    initial begin
        rom[0] = 32'h004182b3;  // ADD X5, X3, X4
        rom[1] = 32'h403281b3;
        rom[2] = 32'hb3;
        rom[3] = 32'hb3;
        rom[4] = 32'hb3;
        rom[5] = 32'hb3;
        rom[6] = 32'hb3;
        rom[7] = 32'hb3;
        rom[8] = 32'hb3;
        rom[9] = 32'hb3;
    end

    // [31:2] 로 시뮬레이션 시간을 단축?
    assign instr_data = rom[instr_addr[31:2]];

endmodule
