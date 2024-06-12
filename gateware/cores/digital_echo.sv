// Digital echo effect.
//
// Given input audio on input 0 / 1, apply a digital echo effect.
//
// Mapping:
// - Input 0: Audio input 0
// - Output 0: Audio input 0 (mirrored)
// - Output 1: Audio input 0 (echo)

module digital_echo #(
    parameter W = 16,
    // Length of the echo buffers in samples.
    parameter ECHO_LEN = 4096
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

echo #(W, ECHO_LEN) echo0(
    .clk(clk),
    .strobe(strobe),
    .sample_in(sample_in0),
    .sample_out(sample_out1)
);

assign sample_out0 = sample_in0;

endmodule
