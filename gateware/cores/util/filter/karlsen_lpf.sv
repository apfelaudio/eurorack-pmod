/*
    Karlsen Fast Ladder low-pass filter.

    Hacky non-pipelined version used for prototyping.

    Inspired by:
    https://www.musicdsp.org/en/latest/Filters/240-karlsen-fast-ladder.html

    Translated to Verilog by Seb (me@sebholzapfel.com)

    Note on parameters and fixed point scaling:
    - g = cutoff = tan(pi * cutoff_freq / fs) => (0 is 0, 1 is about 0.2fs)
       -> Fixed point we expect g is in [0, 32768], where 32678 represents 1 (0.2fs)
    - resonance scales from 0 to 4 (where 4 is far in self-oscillation)
       -> Fixed point we expect resonance in [0, 32768] wher 32768 scales to 2.
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

`define CLAMP(x) ((x>MAX)?MAX:((x<MIN)?MIN:x))
`define CLAMP_POSITIVE(x) ((x<0)?0:W2'(x))

localparam W2 = W*2;
localparam signed [W2-1:0] MAX = (2**(W-1))-1;
localparam signed [W2-1:0] MIN = -(2**(W-1));

logic signed [W2-1:0] in_ex;
logic signed [W2-1:0] g_ex;
logic signed [W2-1:0] resonance_ex;
logic signed [W2-1:0] rezz;
logic signed [W2-1:0] rezz_cliph;
logic signed [W2-1:0] rezz_clip;
logic signed [W2-1:0] sat;
logic signed [W2-1:0] a1;
logic signed [W2-1:0] a2;
logic signed [W2-1:0] a3;
logic signed [W2-1:0] a4;

assign in_ex = W2'(sample_in);
assign g_ex = `CLAMP_POSITIVE(g);
assign resonance_ex = `CLAMP_POSITIVE(resonance) <<< 2;

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
        rezz <= (in_ex - (((W2'(sample_out) - in_ex) * resonance_ex) >>> W));
        // Saturation (simplified)
        sat <= `CLAMP(rezz);
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
