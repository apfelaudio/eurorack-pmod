//
// Touch-to-CV. Touches on input jacks 1-4 are
// translated into CV outputs on outputs 1-4.
//

`default_nettype none

module touch_cv #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3,
    input [7:0] jack,
    input [7:0] touch0,
    input [7:0] touch1,
    input [7:0] touch2,
    input [7:0] touch3,
    input [7:0] touch4,
    input [7:0] touch5,
    input [7:0] touch6,
    input [7:0] touch7
);

assign sample_out0 = W'(touch0 <<< (W-10));
assign sample_out1 = W'(touch1 <<< (W-10));
assign sample_out2 = W'(touch2 <<< (W-10));
assign sample_out3 = W'(touch3 <<< (W-10));

endmodule
