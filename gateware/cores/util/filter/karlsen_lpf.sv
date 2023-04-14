/*
    Karlsen Fast Ladder III low-pass filter.

    Inspired by:
    https://www.musicdsp.org/en/latest/Filters/240-karlsen-fast-ladder.html

    Translated to Verilog by Seb (me@sebholzapfel.com)
*/

`default_nettype none

module smul_shift_18x18 (
    input signed [17:0] a,
    input signed [17:0] b,
    input signed [17:0] scale,
    output signed [35:0] o
);
assign o = a + (((-a + b) * scale) >>> 16);
endmodule

module karlsen_lpf #(
    parameter W = 16
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] g,
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

// Not pipelined for now...
logic prev_sample_clk;
logic [3:0] state;

logic signed [(W*2)-1:0] in_ex;
logic signed [(W*2)-1:0] g_ex;
/*
logic signed [(W*2)-1:0] resonance_ex;
logic signed [(W*2)-1:0] rezz;
logic signed [(W*2)-1:0] rezz_cliph;
logic signed [(W*2)-1:0] rezz_clip;
logic signed [(W*2)-1:0] sat;
*/
logic signed [(W*2)-1:0] a1;
logic signed [(W*2)-1:0] a2;
logic signed [(W*2)-1:0] a3;
logic signed [(W*2)-1:0] a4;

logic signed [17:0] smul_a, smul_b, smul_scale;
logic signed [35:0] smul_out;

smul_shift_18x18 multiplier(.a(smul_a), .b(smul_b), .scale(smul_scale), .o(smul_out));

assign in_ex = (W*2)'(sample_in);
assign g_ex  = (W*2)'(g > 0 ? g : 0);
/*
assign resonance_ex  = (W*2)'(resonance > 0 ? resonance : 0) <<< 1;

assign rezz_cliph = (rezz      > 32000) ? 32000 : rezz;
assign rezz_clip = (rezz_cliph < -32000) ? -32000 : rezz_cliph;
*/

always_ff @(posedge clk) begin
    prev_sample_clk <= sample_clk;
    if (rst) begin
        state <= 0;
        /*
        rezz <= 0;
        sat <= 0;
        */
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;
        sample_out <= 0;
        prev_sample_clk <= 0;
    end else begin
        if (sample_clk != prev_sample_clk) begin
            state <= 0;
        end else begin
            if (state < 5)
                state <= state + 1;
            case (state)
                0: begin
                    smul_a <= a1;
                    smul_b <= in_ex;
                    smul_scale <= g_ex;
                end
                1: begin
                    a1 <= smul_out;
                    smul_a <= a2;
                    smul_b <= smul_out;
                end
                2: begin
                    a2 <= smul_out;
                    smul_a <= a3;
                    smul_b <= smul_out;
                end
                3: begin
                    a3 <= smul_out;
                    smul_a <= a4;
                    smul_b <= smul_out;
                end
                4: begin
                    a4 <= smul_out;
                    sample_out <= smul_out[W-1:0];
                end
            endcase
        end
        /*
        // Resonance
        rezz <= (in_ex - (((-in_ex + sample_out) * resonance_ex) >>> W));
        // Saturation
        sat <= rezz + (((-rezz + rezz_clip)*31)>>>5);
        // Ladder filter
        a1 <= a1 + (((-a1 + sat) * g_ex) >>> W);
        a2 <= a2 + (((-a2 + a1) * g_ex) >>> W);
        a3 <= a3 + (((-a3 + a2) * g_ex) >>> W);
        a4 <= a4 + (((-a4 + a3) * g_ex) >>> W);
        sample_out <= a4[W-1:0];
        */
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
