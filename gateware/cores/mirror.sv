// Mirror / passthrough. Simply forwards samples unmodified.
//
// Mapping:
// - Input 0-3: input signals
// - Output 0-3: output signals (same as corresponding input)
//
module mirror #(
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
    input [7:0] jack
);

assign sample_out0 = sample_in0;
assign sample_out1 = sample_in1;
assign sample_out2 = sample_in2;
assign sample_out3 = sample_in3;

endmodule
