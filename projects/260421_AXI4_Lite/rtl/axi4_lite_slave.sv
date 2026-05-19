`timescale 1ns / 1ps

module axi4_lite_slave (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // AW channel
    input  logic [31:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // W channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // B channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // AR channel
    input  logic [31:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // R channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP
);

    logic [31:0] register[0:31];
    logic [31:0] awaddr_reg;
    logic [31:0] araddr_reg;

    logic aw_done, w_done, ar_done;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            for (int i = 0; i < 31; i++) begin
                register[i] <= 0;
            end
            aw_done <= 0;
            w_done  <= 0;
            ar_done <= 0;
            RDATA   <= 0;
        end else begin
            // AW Channel
            if (AWVALID && AWREADY) begin
                awaddr_reg <= AWADDR;
                aw_done    <= 1'b1;
            end
            // W Channel
            if (WVALID && WREADY && aw_done) begin
                register[awaddr_reg[6:2]] <= WDATA;
                w_done <= 1'b1;
            end
            // B Channel
            if (BVALID && BREADY) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;
            end
            // AR Channel
            if (ARVALID && ARREADY) begin
                araddr_reg <= ARADDR;
                RDATA      <= register[ARADDR[6:2]];
                ar_done    <= 1'b1;
            end
            // R Channel
            if (RVALID && RREADY) begin
                ar_done <= 1'b0;
            end
        end
    end

    /********************** WRITE TRANSACTION *******************/

    // AW Channel transfer
    typedef enum logic {
        AW_IDLE,
        AW_READY
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE;
        end else begin
            aw_state <= aw_state_next;
        end
    end

    always_comb begin
        aw_state_next = aw_state;
        AWREADY       = 1'b0;
        case (aw_state)
            AW_IDLE: begin
                if (AWVALID && !aw_done) begin
                    aw_state_next = AW_READY;
                end
            end
            AW_READY: begin
                AWREADY = 1'b1;
                aw_state_next = AW_IDLE;
            end
        endcase
    end

    // W Channel transfer
    typedef enum logic {
        W_IDLE,
        W_READY
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY       = 1'b0;
        case (w_state)
            W_IDLE: begin
                if (WVALID && aw_done && !w_done) begin
                    w_state_next = W_READY;
                end
            end
            W_READY: begin
                WREADY = 1'b1;
                w_state_next = W_IDLE;
            end
        endcase
    end

    // B Channel transfer
    typedef enum logic {
        B_IDLE,
        B_VALID
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BRESP        = 2'b00;
        BVALID       = 1'b0;
        case (b_state)
            B_IDLE: begin
                if (aw_done && w_done) begin
                    b_state_next = B_VALID;
                end
            end
            B_VALID: begin
                BRESP  = 2'b00;
                BVALID = 1'b1;
                if (BREADY) begin
                    b_state_next = B_IDLE;
                end
            end
        endcase
    end

    /******************** READ TRANSACTION *********************/

    // AR Channel transfer
    typedef enum logic {
        AR_IDLE,
        AR_READY
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ARREADY = 1'b0;
        case (ar_state)
            AR_IDLE: begin
                if (ARVALID && !ar_done) begin
                    ar_state_next = AR_READY;
                end
            end
            AR_READY: begin
                ARREADY = 1'b1;
                ar_state_next = AR_IDLE;
            end
        endcase
    end

    // R Channel transfer
    typedef enum logic {
        R_IDLE,
        R_VALID
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID       = 1'b0;
        RRESP        = 2'b00;
        case (r_state)
            R_IDLE: begin
                if (ar_done) begin
                    r_state_next = R_VALID;
                end
            end
            R_VALID: begin
                RVALID = 1'b1;
                RRESP  = 2'b00;
                if (RREADY) begin
                    r_state_next = R_IDLE;
                end
            end
        endcase
    end
endmodule
