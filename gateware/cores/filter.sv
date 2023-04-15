// Audio-rate low-pass filter with resonance + saturation
//
// Mapping:
// - Input 0: Audio input
// - Input 1: Frequency cutoff (0V muted, 10V open)
// - Input 2: Resonance (0V none, 10V close to self-oscillation)
// - Input 2/3: Unused
// - Output 0: Lowpass out
// - Output 1-3: Unused

module filter #(
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

karlsen_lpf_pipelined #(.W(W)) lpf_inst(
    .rst(rst),
    .clk(clk),
    .sample_clk(sample_clk),
    .sample_in(sample_in0),
    .sample_out(sample_out0),
    .g(sample_in1),
    .resonance(sample_in2)
);

endmodule
