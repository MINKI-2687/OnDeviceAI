`timescale 1ns / 1ps
`include "define.vh"

module data_mem (
    input               clk,
    input        [ 2:0] i_funct3,
    input               dwe,
    input        [31:0] daddr,
    input        [31:0] dwdata,
    output logic [31:0] drdata
);

    // word address
    logic [31:0] dmem[0:255];

    // S-type (store)
    always_ff @(posedge clk) begin
        if (dwe) begin
            case (i_funct3)
                `SB: begin
                    case (daddr[1:0])   // 4가 한 묶음인데, 그 안에서 4byte의 주소를 지정
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8] <= dwdata[7:0];
                        2'b00: dmem[daddr[31:2]][7:0] <= dwdata[7:0];
                    endcase
                end
                `SH: begin
                    case (daddr[1])  // 4byte 중 2byte, 2byte로 나눔
                        1'b1: dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                        1'b0: dmem[daddr[31:2]][15:0] <= dwdata[15:0];
                    endcase
                end
                `SW: begin
                    dmem[daddr[31:2]] <= dwdata;  // SW
                end
            endcase
        end
    end

    // IL-type (load)
    always_comb begin
        drdata = 32'h0000;
        case (i_funct3)
            `LB: begin  // LB
                case (daddr[1:0])
                    2'b11:
                    drdata = {
                        {24{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:24]
                    };
                    2'b10:
                    drdata = {
                        {24{dmem[daddr[31:2]][23]}}, dmem[daddr[31:2]][23:16]
                    };
                    2'b01:
                    drdata = {
                        {24{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:8]
                    };
                    2'b00:
                    drdata = {
                        {24{dmem[daddr[31:2]][7]}}, dmem[daddr[31:2]][7:0]
                    };
                endcase
            end
            `LH: begin  // LH
                case (daddr[1])
                    1'b1:
                    drdata = {
                        {16{dmem[daddr[31:2]][31]}}, dmem[daddr[31:2]][31:16]
                    };
                    1'b0:
                    drdata = {
                        {16{dmem[daddr[31:2]][15]}}, dmem[daddr[31:2]][15:0]
                    };
                endcase
            end
            `LW: begin  // LW
                drdata = dmem[daddr[31:2]];
            end
            `LBU: begin  // LBU
                case (daddr[1:0])
                    2'b11: drdata = {24'd0, dmem[daddr[31:2]][31:24]};
                    2'b10: drdata = {24'd0, dmem[daddr[31:2]][23:16]};
                    2'b01: drdata = {24'd0, dmem[daddr[31:2]][15:8]};
                    2'b00: drdata = {24'd0, dmem[daddr[31:2]][7:0]};
                endcase
            end
            `LHU: begin  // LHU
                case (daddr[1])
                    1'b1: drdata = {16'd0, dmem[daddr[31:2]][31:16]};
                    1'b0: drdata = {16'd0, dmem[daddr[31:2]][15:0]};
                endcase
            end
        endcase
    end
endmodule
