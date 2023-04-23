// Wavetable VCO tuned to 1V/Oct.
//
// Mapping:
// - Input 0: V/Oct input, C3 is +3V
// - Output 0: VCO output (from wavetable).

`default_nettype none

module vco #(
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

logic signed [W-1:0] vco_out;
logic signed [W-1:0] filter_out;
logic signed [W-1:0] pitch_out;

wavetable_vco #(.W(W), .FDIV(1)) vco_inst (
    .rst(rst),
    .sample_clk(sample_clk),
    .frequency(sample_in0),
    .out(vco_out)
);

karlsen_lpf_pipelined #(.W(W)) lpf_inst(
    .rst(rst),
    .clk(clk),
    .sample_clk(sample_clk),
    .sample_in(vco_out),
    .sample_out(filter_out),
    .g(sample_in1),
    .resonance(sample_in2)
);

transpose transpose_instance (
    .sample_clk(sample_clk),
    .pitch(sample_in3),
    .sample_in(filter_out),
    .sample_out(pitch_out)
);

assign sample_out0 = vco_out;
assign sample_out1 = filter_out;
assign sample_out2 = pitch_out;
assign sample_out3 = (filter_out >>> 1) + (pitch_out >>> 1);

endmodule
