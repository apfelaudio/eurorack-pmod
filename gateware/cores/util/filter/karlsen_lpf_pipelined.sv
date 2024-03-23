/*
    Karlsen Fast Ladder low-pass filter.

    Pipelined version that only requires 1 18x18 multiplier block.

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

// Helper module to perform one `a + (b - a) * scale` operation. The
// ladder filter does this operation 5 times in a row so this is shared.
module smul_shift_18x18 (
    input signed [17:0] a,
    input signed [17:0] b,
    input signed [17:0] scale,
    output signed [35:0] o
);
assign o = 36'(a) + (36'(18'(-a + b) * 18'(scale)) >>> 16);
endmodule

module karlsen_lpf_pipelined #(
    parameter W = 16
)(
    input rst,
    input clk,
    input strobe,
    // See header comment for what these parameters mean.
    input signed [W-1:0] g,
    input signed [W-1:0] resonance,
    input signed [W-1:0] sample_in,
    output logic signed [W-1:0] sample_out
);


`define CLAMP(x) ((x>MAX)?MAX:((x<MIN)?MIN:x))
`define CLAMP_POSITIVE(x) ((x<0)?0:WMULT'(x))

localparam WMULT = 18; // Width of multiplier input
localparam signed [WMULT-1:0] MAX = (2**(W-1))-1;
localparam signed [WMULT-1:0] MIN = -(2**(W-1));

logic [3:0] state;

logic signed [WMULT-1:0] in_ex;
logic signed [WMULT-1:0] g_ex;
logic signed [WMULT-1:0] resonance_ex;

logic signed [WMULT-1:0] clip;
logic signed [WMULT-1:0] a1;
logic signed [WMULT-1:0] a2;
logic signed [WMULT-1:0] a3;
logic signed [WMULT-1:0] a4;

logic signed [WMULT-1:0] smul_a, smul_b, smul_scale;
logic signed [35:0] smul_out;

assign in_ex = WMULT'(sample_in);
assign g_ex = `CLAMP_POSITIVE(g);
assign resonance_ex = `CLAMP_POSITIVE(resonance) <<< 2;

smul_shift_18x18 multiplier(.a(smul_a), .b(smul_b), .scale(smul_scale), .o(smul_out));

always_ff @(posedge clk) begin
    if (rst) begin
        state <= 0;
        a1 <= 0;
        a2 <= 0;
        a3 <= 0;
        a4 <= 0;
        sample_out <= 0;
    end else begin
        if (strobe) begin
            state <= 0;
        end else begin
            if (state < 8)
                state <= state + 1;
            case (state)
                0: begin
                    // Resonance
                    // rezz <= (in_ex - (((W2'(sample_out) - in_ex) * resonance_ex) >>> W));
                    smul_a <= WMULT'(in_ex);
                    smul_b <= a4;
                    smul_scale <= resonance_ex;
                end
                1: begin
                    // Fix sign of smul_shift operation
                    clip <= (in_ex<<<1) - WMULT'(smul_out);
                end
                2: begin
                    // Saturation (simplified)
                    clip <= `CLAMP(clip);
                end
                3: begin
                    // a1 <= a1 + (((-a1 + sat) * g_ex) >>> W);
                    smul_a <= a1;
                    smul_b <= clip;
                    smul_scale <= g_ex;
                end
                4: begin
                    // a2 <= a2 + (((-a2 + a1) * g_ex) >>> W);
                    a1 <= WMULT'(smul_out);
                    smul_a <= a2;
                    smul_b <= WMULT'(smul_out);
                end
                5: begin
                    // a3 <= a3 + (((-a3 + a2) * g_ex) >>> W);
                    a2 <= WMULT'(smul_out);
                    smul_a <= a3;
                    smul_b <= WMULT'(smul_out);
                end
                6: begin
                    // a4 <= a4 + (((-a4 + a3) * g_ex) >>> W);
                    a3 <= WMULT'(smul_out);
                    smul_a <= a4;
                    smul_b <= WMULT'(smul_out);
                end
                7: begin
                    a4 <= WMULT'(smul_out);
                    sample_out <= smul_out[W-1:0];
                end
                default: begin
                    // Sit here until next sample.
                end
            endcase
        end
    end
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("karlsen_lpf_pipelined.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
