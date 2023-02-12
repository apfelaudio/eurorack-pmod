// Transpose / pitch shift.
//
// Given input audio on input 0, pitch shift it.
//
// This core saves incoming samples into 2 delay lines, plays them
// back at modified speed, and cross-fades between them to avoid
// discontinuities. Basically we chop up the input into grains of
// size WINDOW and speed/slow playback in the time domain. This allows
// us to do pitch shifting without time stretching.
//
// Mapping:
// - Input 0: Audio input
// - Input 1: Pitch shift amount (CV, not 1V/oct yet)
// - Output 0: Audio input (mirrored)
// - Output 1: Audio input (transposed)
// - Output 2: Audio input (dry + transposed mixed)

module transpose #(
    parameter W = 16,
    parameter FP_OFFSET = 2,
    parameter WINDOW = 512,
    parameter XFADE = 64
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

// Fractional delay and the offset fed into delay lines.
logic signed [15:0] d = 0;
logic [8:0] delay;

// Output of the delay lines
logic signed [W-1:0] delay_out0;
logic signed [W-1:0] delay_out1;

// Cross-fading envelopes
logic [7:0] env0;
logic [7:0] env1;
logic signed [7:0] env0_reg;
logic signed [7:0] env1_reg;

// Some LSBs of `d` are fractional.
assign delay = d[15:7];

delayline delay_0(
    .sample_clk(sample_clk),
    .delay(10'(delay)),
    .in(sample_in0),
    .out(delay_out0)
);

delayline delay_1(
    .sample_clk(sample_clk),
    .delay(10'(delay)+WINDOW),
    .in(sample_in0),
    .out(delay_out1)
);

always_ff @(posedge sample_clk) begin
    // The value we increment `d` by here is actually the 'pitch shift' amount.
    // walking up the delay lines some amount faster or slower than usual.
    d <= d + (sample_in1 >>> 8);

    if (delay < XFADE) begin
        env0 <= delay[7:0];
        env1 <= (XFADE-1) - delay[7:0];
    end else begin
        env0 <= XFADE-1;
        env1 <= 0;
    end

    // Envelopes need to be delayed by 1 sample to avoid discontinuity.
    env0_reg <= env0;
    env1_reg <= env1;

    sample_out1 <= 16'((32'(delay_out0) * 32'(env0_reg)) >>> ($clog2(XFADE))) +
                   16'((32'(delay_out1) * 32'(env1_reg)) >>> ($clog2(XFADE)));
end

assign sample_out0 = sample_in0;
assign sample_out2 = (sample_in0 >>> 1) + (sample_out1 >>> 1);

endmodule
