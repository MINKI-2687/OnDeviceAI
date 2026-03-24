`timescale 1ns / 1ps

module rv32i_mcu (
    input clk,
    input rst
);
    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata;
    logic bus_wreq, bus_rreq, bus_ready;



    instruction_mem U_INSTRUCTION_MEM (.*);

    rv32i_cpu U_RV32I (
        .*,
        .o_funct3(o_funct3)
    );

    apb_master U_APB_MASTER (
        .pclk   (clk),
        .presetn(rst),
        //---------------------------------------
        // SoC Internal signal with CPU
        // pc -> master
        .addr   (bus_addr),
        .wdata  (bus_wdata),
        .wreq   (bus_wreq),   // write request, signal cpu : dwe
        .rreq   (bus_rreq),   // read request,  signal cpu : dre
        // master -> pc
        .rdata  (bus_rdata),
        .ready  (bus_ready)
        //---------------------------------------
        // APB Interface signal
        // slave -> master
        // ram
        // .prdata0(),
        // .pready0(),
        // // gpo
        // .prdata1(),
        // .pready1(),
        // // gpi
        // .prdata2(),
        // .pready2(),
        // // gpio
        // .prdata3(),
        // .pready3(),
        // // fnd
        // .prdata4(),
        // .pready4(),
        // // uart
        // .prdata5(),
        // .pready5(),
        // // master -> slave
        // .paddr  (),           // need register
        // .pwdata (),           // need register
        // .penable(),           // need register
        // .pwrite (),           // need register
        // .psel0  (),           // RAM
        // .psel1  (),           // GPO
        // .psel2  (),           // GPI
        // .psel3  (),           // GPIO
        // .psel4  (),           // FND
        // .psel5  ()            // UART
        //--------------------------------------
    );

    // data_mem U_DATA_MEM (
    //     .*,
    //     .i_funct3(o_funct3)
    // );

endmodule
