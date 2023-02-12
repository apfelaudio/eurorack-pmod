// Transpose / pitch shift.
//
// Given input audio, pitch shift it.
//
// This core saves incoming samples into 2 delay lines, plays them
// back at modified speed, and cross-fades between them to avoid
// discontinuities. Basically we chop up the input into grains of
// size WINDOW and speed/slow playback in the time domain. This allows
// us to do pitch shifting without time stretching.

module transpose #(
    parameter W = 16,
    parameter WINDOW = 512,
    parameter XFADE = 64
)(
    input sample_clk,
    input signed [W-1:0] pitch,
    input signed [W-1:0] sample_in,
    output logic signed [W-1:0] sample_out
);

localparam DELAY_INT_BITS  = $clog2(WINDOW);
localparam DELAY_FRAC_BITS = DELAY_INT_BITS + 7;
localparam XFADE_BITS = $clog2(XFADE);

// Fractional delay and the offset fed into delay lines.
logic signed [DELAY_FRAC_BITS-1:0] delay_frac = 0;
logic [DELAY_INT_BITS-1:0]         delay_int;
assign delay_int = delay_frac[DELAY_FRAC_BITS-1:DELAY_FRAC_BITS-DELAY_INT_BITS];

// Output of the delay lines
logic signed [W-1:0] delay_out0;
logic signed [W-1:0] delay_out1;

// Cross-fading envelopes
logic [XFADE_BITS:0] env0;
logic [XFADE_BITS:0] env1;
logic signed [XFADE_BITS:0] env0_reg;
logic signed [XFADE_BITS:0] env1_reg;


delayline delay_0(
    .sample_clk(sample_clk),
    .delay({1'b0, delay_int}),
    .in(sample_in),
    .out(delay_out0)
);

delayline delay_1(
    .sample_clk(sample_clk),
    .delay({1'b0, delay_int}+WINDOW),
    .in(sample_in),
    .out(delay_out1)
);

always_ff @(posedge sample_clk) begin
    // The value we increment `d` by here is actually the 'pitch shift' amount.
    // walking up the delay lines some amount faster or slower than usual.
    //
    // TODO: Make this track 1V/oct.
    delay_frac <= delay_frac + (pitch >>> 8);

    if (delay_int < XFADE) begin
        env0 <= delay_int[XFADE_BITS:0];
        env1 <= (XFADE-1) - delay_int[XFADE_BITS:0];
    end else begin
        env0 <= XFADE-1;
        env1 <= 0;
    end

    // Envelopes need to be delayed by 1 sample to avoid discontinuity.
    env0_reg <= env0;
    env1_reg <= env1;

    // TODO: pipeline these multiplies.
    sample_out <= W'(((W+XFADE_BITS)'(delay_out0) * (W+XFADE_BITS)'(env0_reg)) >>> XFADE_BITS) +
                  W'(((W+XFADE_BITS)'(delay_out1) * (W+XFADE_BITS)'(env1_reg)) >>> XFADE_BITS);
end

endmodule
