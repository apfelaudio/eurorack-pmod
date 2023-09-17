// VCO tuned to 1V/Oct.
//
// Mapping:
// - Input 0: V/Oct input, C3 is +3V
// - Output 0: VCO output (from wavetable)

module vco #(
    parameter W = 16,
    parameter V_OCT_LUT_PATH = "cores/util/vco/v_oct_lut.hex",
    parameter V_OCT_LUT_SIZE = 512,
    parameter WAVETABLE_PATH = "cores/util/vco/wavetable.hex",
    parameter WAVETABLE_SIZE = 256,
    parameter FDIV = 0 // Divide output frequency by 1 << FDIV.
                       // Useful if you want to use this as an LFO.
)(
    input rst,
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3,
    input [7:0] jack
);

// Look up table mapping from volts to frequency.
// Table indices are (mV*4) >> 6 (so correct index is just sample >> 6.
// Table values are amount to increment wavetable position, assuming
// wavetable position is N.F bits, where N is index into wavetable, and
// F matches frac_bits_delta in LUT generation script.
logic [W-1:0] v_oct_lut [0:V_OCT_LUT_SIZE-1];
initial $readmemh(V_OCT_LUT_PATH, v_oct_lut);

// For < 0V input, clamp to bottom note.
logic signed [W-1:0] lut_index = 0;
logic signed [W-1:0] lut_index_clamp_lo = 0;

always_ff @(posedge sample_clk) begin
    if (rst) begin
        lut_index <= 0;
        lut_index_clamp_lo <= 0;
    end else begin
        lut_index <= sample_in0 >>> 6;
        lut_index_clamp_lo <= lut_index < 0 ? 0 : lut_index;
    end
end

wavetable_osc #(
    .W(W),
    .FRAC_BITS(10),
    .WAVETABLE_PATH(WAVETABLE_PATH),
    .WAVETABLE_SIZE(WAVETABLE_SIZE)
) osc_0 (
    .rst(rst),
    .sample_clk(sample_clk),
    .wavetable_inc(32'(v_oct_lut[$clog2(V_OCT_LUT_SIZE)'(lut_index_clamp_lo)])),
    .out(sample_out0)
);

endmodule
