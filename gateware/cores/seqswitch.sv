// Sequential switch
//
// Given an input clock source on input 0, combine inputs 1 - 3 together
// to create sequentially switched outputs 1 - 3.
//
// Mapping:
// - Input 0: Switch clock input (Hi > 2V, Lo < 0.5V)
// - Input 1-3: Sequential switch signal inputs to be routed to
//              different outputs on every rising edge of clock.
// - Output 0: Clock (mirrored)
// - Output 1: Input 1 -> 2 -> 3 -> 1 ...
// - Output 2: Input 2 -> 3 -> 1 -> 2 ...
// - Output 3: Input 3 -> 1 -> 2 -> 3 ...

module seqswitch #(
    parameter W = 16,
    parameter FP_OFFSET = 2
)(
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3
);

// Calibrated samples represent millivolts in 16 bits, last 2 bits are fractional.
`define FROM_MV(value) (value <<< FP_OFFSET);

// Input and output voltage thresholds.
localparam SCHMITT_HI = `FROM_MV(2000)
localparam SCHMITT_LO = `FROM_MV(500)

// State variable for schmitt inputs.
logic last_state_hi = 1'b0;

// Current routing state of the sequential switch.
logic [1:0] switch_state = 2'b00;

always_ff @(posedge sample_clk) begin

    // Rising edge of clock.
    if (sample_in0 > SCHMITT_HI && !last_state_hi) begin
        last_state_hi <= 1'b1;

        // Update switch routing on a rising edge.
        if (switch_state == 2'b10) switch_state <= 2'b00;
        else switch_state <= switch_state + 1;
    end

    // Falling edge of clock.
    if (sample_in0 < SCHMITT_LO && last_state_hi) begin
        last_state_hi <= 1'b0;
    end

    // Samples mirrored at audio rate based on current routing.
    case (switch_state)
        2'b00: begin
            sample_out1 <= sample_in1;
            sample_out2 <= sample_in2;
            sample_out3 <= sample_in3;
        end
        2'b01: begin
            sample_out1 <= sample_in2;
            sample_out2 <= sample_in3;
            sample_out3 <= sample_in1;
        end
        2'b10: begin
            sample_out1 <= sample_in3;
            sample_out2 <= sample_in1;
            sample_out3 <= sample_in2;
        end
        default: begin
            // State is never entered
        end
    endcase
end

assign sample_out0 = sample_in0;

endmodule
