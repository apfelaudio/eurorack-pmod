// Precision multiplier (VCA with polarization)
//
// Given an input voltage, multiply input audio by input voltage. This VCA
// performs polarization so negative voltages will also amplify, but with
// inverted phase. Both inputs are audio rate.
//
// Mapping:
// - Input 0: Gain input #1
// - Input 1: Signal input #1
// - Input 2: Gain input #2
// - Input 3: Signal input #2
// - Output 0: Input #1 (mirrored)
// - Output 1: Input 0 * Input 1
// - Output 2: Input #3 (mirrored)
// - Output 3: Input 2 * Input 3
//
module vca (
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

wire signed [31:0] vca1 = sample_in0 * sample_in1;
wire signed [31:0] vca2 = sample_in2 * sample_in3;

assign sample_out0 = sample_in0;
assign sample_out1 = vca1 >>> 16;
assign sample_out2 = sample_in2;
assign sample_out3 = vca2 >>> 16;

endmodule
