// Audio-rate state-variable filter
//
// Mapping:
// - Input 0: Audio input
// - Input 1: Frequency cutoff (about -5V to 5V)
// - Input 2/3: Unused
// - Output 0: Highpass out
// - Output 1: Lowpass out
// - Output 2: Bandpass out
// - Output 3: Notch out

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


logic signed[W-1:0] dc_blocked;

dc_block #(.W(W)) dc_block_inst(
    .sample_clk(sample_clk),
    .sample_in(sample_in0),
    .sample_out(dc_blocked)
);

karlsen_lpf #(.W(W)) lpf_inst(
    .rst(rst),
    .clk(clk),
    .sample_clk(sample_clk),
    .in(dc_blocked),
    .out(sample_out0),
    .g(sample_in1),
    .resonance(sample_in2)
);

endmodule
