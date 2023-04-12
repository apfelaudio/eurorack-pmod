/*
    Karlsen Fast Ladder III low-pass filter.

    Inspired by:
    https://www.musicdsp.org/en/latest/Filters/240-karlsen-fast-ladder.html
*/

module karlsen_lpf #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] in,
    input signed [W-1:0] g,           // tan(pi * cutoff_freq / fs) => (0 is 0, 1 is about 0.2fs)
    input signed [W-1:0] resonance,   // 0 to 4 (self oscillation)
    output logic signed [W-1:0] out
);

// Not pipelined for now...
logic [3:0] state;

logic signed [W*2-1:0] in_ex;
logic signed [W*2-1:0] g_ex;
logic signed [W*2-1:0] resonance_ex;
logic signed [W*2-1:0] a0;
logic signed [W*2-1:0] a1;
logic signed [W*2-1:0] a2;
logic signed [W*2-1:0] a3;
logic signed [W*2-1:0] a4;

assign in_ex = (W*2)'(in);
assign g_ex  = (W*2)'(g > 0 ? g : 0);
assign resonance_ex  = (W*2)'(resonance > 0 ? resonance : 0) <<< 1;

always_ff @(posedge sample_clk) begin
    if (rst) begin
        state <= 0;
        a0 <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;
    end else begin
        // Resonance
        a0 = in_ex - (((out - in_ex) * resonance_ex) >>> W);
        // Ladder filter
        a1 = a1 + (((-a1 + a0) * g_ex) >>> W);
        a2 = a2 + (((-a2 + a1) * g_ex) >>> W);
        a3 = a3 + (((-a3 + a2) * g_ex) >>> W);
        a4 = a4 + (((-a4 + a3) * g_ex) >>> W);
        out <= a4[W-1:0];
    end
end

endmodule
