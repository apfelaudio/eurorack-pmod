/*
    Karlsen Fast Ladder III low-pass filter.

    Inspired by:
    https://www.musicdsp.org/en/latest/Filters/240-karlsen-fast-ladder.html
*/

`default_nettype none

module karlsen_lpf #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] g,           // tan(pi * cutoff_freq / fs) => (0 is 0, 1 is about 0.2fs)
    input signed [W-1:0] resonance,   // 0 to 4 (self oscillation)
    input signed [W-1:0] sample_in,
    output logic signed [W-1:0] sample_out
);

/* Note on parameters and fixed point scaling:
 * - g = cutoff = tan(pi * cutoff_freq / fs) => (0 is 0, 1 is about 0.2fs)
 *    -> Fixed point we expect g is in [0, 32768], where 32678 represents 1 (0.2fs)
 * resonance scales from 0 to 4 (where 4 is far in self-oscillation)
 *    -> Fixed point we expect resonance in [0, 32768] wher 32768 scales to 2.
 */

logic signed [(W*2)-1:0] in_ex;
logic signed [(W*2)-1:0] g_ex;
logic signed [(W*2)-1:0] resonance_ex;
logic signed [(W*2)-1:0] rezz;
logic signed [(W*2)-1:0] rezz_cliph;
logic signed [(W*2)-1:0] rezz_clip;
logic signed [(W*2)-1:0] sat;
logic signed [(W*2)-1:0] a1;
logic signed [(W*2)-1:0] a2;
logic signed [(W*2)-1:0] a3;
logic signed [(W*2)-1:0] a4;

assign in_ex = (W*2)'(sample_in);
assign g_ex  = (W*2)'(g > 0 ? g : 0);
assign resonance_ex  = (W*2)'(resonance > 0 ? resonance : 0) <<< 1;

assign rezz_cliph = (rezz      > 32000) ? 32000 : rezz;
assign rezz_clip = (rezz_cliph < -32000) ? -32000 : rezz_cliph;

always_ff @(posedge sample_clk) begin
    if (rst) begin
        rezz <= 0;
        sat <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;
        sample_out <= 0;
    end else begin
        // Resonance
        rezz <= (in_ex - (((sample_out - in_ex) * resonance_ex) >>> W));
        // Saturation
        sat <= rezz + (((-rezz + rezz_clip)*31)>>>5);
        // Ladder filter
        a1 <= a1 + (((-a1 + sat) * g_ex) >>> W);
        a2 <= a2 + (((-a2 + a1) * g_ex) >>> W);
        a3 <= a3 + (((-a3 + a2) * g_ex) >>> W);
        a4 <= a4 + (((-a4 + a3) * g_ex) >>> W);
        sample_out <= a4[W-1:0];
    end
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("karlsen_lpf.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
