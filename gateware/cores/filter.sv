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

module filter (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] sample_in0,
    input signed [15:0] sample_in1,
    input signed [15:0] sample_in2,
    input signed [15:0] sample_in3,
    output signed [15:0] sample_out0,
    output signed [15:0] sample_out1,
    output signed [15:0] sample_out2,
    output signed [15:0] sample_out3
);

filter_svf_pipelined #(.SAMPLE_BITS(16)) filter_svf_inst(
    .clk(clk),
    .in(sample_in0),
    .sample_clk(sample_clk),
    .out_highpass(sample_out0),
    .out_lowpass(sample_out1),
    .out_bandpass(sample_out2),
    .out_notch(sample_out3),
    // Scale so -5V to 5V is (very) roughly 100Hz -> 10Khz.
    .F((-sample_in1>>>1) - 15000),
    // TODO: control this from another input?
    .Q1(-32000)
);

endmodule
