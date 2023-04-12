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
//    input [W-1:0] resonance,   // 0 to 4 (self oscillation)
    output logic signed [W-1:0] out
);

// Not pipelined for now...
logic [3:0] state;

logic signed [W*2-1:0] in_ex;
logic signed [W*2-1:0] g_ex;
logic signed [W*2-1:0] a0;
logic signed [W*2-1:0] a1;
logic signed [W*2-1:0] a2;
logic signed [W*2-1:0] a3;
logic signed [W*2-1:0] a4;

assign in_ex = (W*2)'(in);
assign g_ex  = (W*2)'((g > 0 ? g : 0))>>>2;

always_ff @(posedge sample_clk) begin
    if (rst) begin
        state <= 0;
        a0 <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;
    end else begin
        //a0 = in_ex - ((a4 - in_ex) <<< 2);
        a0 = in_ex;
        a1 = a1 + (((-a1 + a0) * g_ex) >>> 16);
        a2 = a2 + (((-a2 + a1) * g_ex) >>> 16);
        a3 = a3 + (((-a3 + a2) * g_ex) >>> 16);
        a4 = a4 + (((-a4 + a3) * g_ex) >>> 16);
        out <= a4[15:0];
    end
end

endmodule
