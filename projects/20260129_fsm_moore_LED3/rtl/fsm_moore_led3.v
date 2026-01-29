`timescale 1ns / 1ps

module fsm_moore_led3 (
    input        clk,
    input        reset,
    input  [2:0] sw,
    output [2:0] led
);
    // state define
    parameter S0 = 3'b000, S1 = 3'b001, S2 = 3'b010, S3 = 3'b011, S4 = 3'b100;

    // state reg variable
    reg [2:0] current_state, next_state;
    reg [2:0] current_led, next_led;

    // output
    assign led = current_led;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            current_state <= S0;
            current_led   <= 3'b000;
        end else begin
            current_state <= next_state;
            current_led   <= next_led;
        end
    end

    // next state CL
    always @(*) begin
        // this always initialize for full case
        next_state = current_state;
        next_led   = current_led;
        case (current_state)
            S0: begin
                // output led
                next_led = 3'b000;
                if (sw == 3'b001) begin
                    next_state = S1;
                end else if (sw == 3'b010) begin
                    next_state = S2;
                end else begin
                    next_state = current_state;
                end
            end
            S1: begin
                next_led = 3'b001;
                if (sw == 3'b010) begin
                    next_state = S2;
                end else begin
                    next_state = current_state;
                end
            end
            S2: begin
                next_led = 3'b010;
                if (sw == 3'b100) begin
                    next_state = S3;
                end else begin
                    next_state = current_state;
                end
            end
            S3: begin
                next_led = 3'b100;
                if (sw == 3'b000) begin
                    next_state = S0;
                end else if (sw == 3'b011) begin
                    next_state = S1;
                end else if (sw == 3'b111) begin
                    next_state = S4;
                end else begin
                    next_state = current_state;
                end
            end
            S4: begin
                next_led = 3'b111;
                if (sw == 3'b000) begin
                    next_state = S0;
                end else begin
                    next_state = current_state;
                end
            end
            default: next_state = current_state;  // protect latch
        endcase
    end

    // output CL
    //assign led = (current_state == S1) ? 2'b01 :
    //             (current_state == S2) ? 2'b11 : 2'b00;
    //always @(*) begin
    //    case (current_state)
    //        S0: led = 3'b000;
    //        S1: led = 3'b001;
    //        S2: led = 3'b010;
    //        S3: led = 3'b100;
    //        S4: led = 3'b111;
    //        default: led = 3'b000;
    //    endcase
    //end

endmodule
