// Transpose / pitch shift.
//
// Given input audio on input 0, pitch shift it.
//
// Mapping:
// - Input 0: Audio input
// - Input 1: Pitch shift amount (CV, not 1V/oct yet)
// - Output 0: Audio input (mirrored)
// - Output 1: Audio input (transposed)
// - Output 2: Audio input (dry + transposed mixed)

module pitch_shift #(
    parameter W = 16
)(
    input rst,
    input clk,
    input strobe,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output logic signed [W-1:0] sample_out0,
    output logic signed [W-1:0] sample_out1,
    output logic signed [W-1:0] sample_out2,
    output logic signed [W-1:0] sample_out3,
    input [7:0] jack
);

transpose #(
    .W(W)
) transpose_instance (
    .clk,
    .strobe,
    .pitch(sample_in1),
    .sample_in(sample_in0),
    .sample_out(sample_out1)
);

assign sample_out0 = sample_in0;
assign sample_out2 = (sample_in0 >>> 1) + (sample_out1 >>> 1);

endmodule
