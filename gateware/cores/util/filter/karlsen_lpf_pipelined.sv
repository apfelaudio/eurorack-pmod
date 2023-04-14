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

module karlsen_lpf_pipelined #(
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


logic prev_sample_clk;
logic [3:0] state;

logic signed [(W*2)-1:0] in_ex;
logic signed [(W*2)-1:0] g_ex;
logic signed [(W*2)-1:0] resonance_ex;

logic signed [(W*2)-1:0] clip;
logic signed [(W*2)-1:0] a1;
logic signed [(W*2)-1:0] a2;
logic signed [(W*2)-1:0] a3;
logic signed [(W*2)-1:0] a4;

logic signed [17:0] smul_a, smul_b, smul_scale;
logic signed [35:0] smul_out;

smul_shift_18x18 multiplier(.a(smul_a), .b(smul_b), .scale(smul_scale), .o(smul_out));

assign in_ex = (W*2)'(sample_in);
assign g_ex  = (W*2)'(g > 0 ? g : 0);
assign resonance_ex  = (W*2)'(resonance > 0 ? resonance : 0) <<< 2;

always_ff @(posedge clk) begin
    prev_sample_clk <= sample_clk;
    if (rst) begin
        state <= 0;
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
            if (state < 8)
                state <= state + 1;
            case (state)
                0: begin
                    smul_a <= in_ex;
                    smul_b <= a4;
                    smul_scale <= resonance_ex;
                end
                1: begin
                    clip <= (in_ex<<<1) - smul_out;
                end
                2: begin
                    clip <= clip > 32000 ? 32000 : clip;
                end
                3: begin
                    clip <= clip < -32000 ? -32000 : clip;
                end
                4: begin
                    smul_a <= a1;
                    smul_b <= clip;
                    smul_scale <= g_ex;
                end
                5: begin
                    a1 <= smul_out;
                    smul_a <= a2;
                    smul_b <= smul_out;
                end
                6: begin
                    a2 <= smul_out;
                    smul_a <= a3;
                    smul_b <= smul_out;
                end
                7: begin
                    a3 <= smul_out;
                    smul_a <= a4;
                    smul_b <= smul_out;
                end
                8: begin
                    a4 <= smul_out;
                    sample_out <= smul_out[W-1:0];
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
