// Dual digital echo effect.
//
// Given input audio on input 0 / 1, apply a digital echo effect.
//
// Mapping:
// - Input 0: Audio input 0
// - Input 1: Audio input 1
// - Output 0: Audio input 0 (mirrored)
// - Output 1: Audio input 0 (echo)
// - Output 2: Audio input 1 (mirrored)
// - Output 3: Audio input 1 (echo)

module stereo_echo #(
    parameter W = 16,
    // Length of the echo buffers in samples.
    parameter ECHO_LEN = 2048,
    // Decimate samples - this allows you to get long echo times
    // without using all the BRAM. Effectively you end up with:
    // ECHO_LEN (effective) = ECHO_LEN * (2 << DECIMATE)
    parameter DECIMATE = 2
)(
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output logic signed [W-1:0] sample_out0,
    output logic signed [W-1:0] sample_out1,
    output logic signed [W-1:0] sample_out2,
    output logic signed [W-1:0] sample_out3
);

logic [15:0] decimate = 0;
logic decimate_clk = decimate[DECIMATE];

always_ff @(posedge sample_clk) begin
    decimate <= decimate + 1;
end

echo #(W, ECHO_LEN) echo0(
    .sample_clk(decimate_clk),
    .sample_in(sample_in0),
    .sample_out(sample_out1)
);

echo #(W, ECHO_LEN) echo1(
    .sample_clk(decimate_clk),
    .sample_in(sample_in1),
    .sample_out(sample_out3)
);

assign sample_out0 = sample_in0;
assign sample_out2 = sample_in1;

endmodule
