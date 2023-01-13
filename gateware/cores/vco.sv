// VCO tuned to 1V/Oct.
//
// Mapping:
// - Input 0: V/Oct input, C3 is +3V
// - Output 0: VCO output (from wavetable)

module vco #(
    parameter W = 16,
    parameter V_OCT_LUT_PATH = "vco/v_oct_lut.hex",
    parameter V_OCT_LUT_SIZE = 512,
    parameter WAVETABLE_PATH = "vco/wavetable.hex",
    parameter WAVETABLE_SIZE = 256
)(
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3
);

// Look up table mapping from volts to frequency.
// Table indices are (mV*4) >> 6 (so correct index is just sample >> 6.
// Table values are amount to increment wavetable position, assuming
// wavetable position is N.F bits, where N is index into wavetable, and
// F matches frac_bits_delta in LUT generation script.
logic [W-1:0] v_oct_lut [0:V_OCT_LUT_SIZE-1];
initial $readmemh(V_OCT_LUT_PATH, v_oct_lut);

logic [W-1:0] wavetable [0:WAVETABLE_SIZE-1];
initial $readmemh(WAVETABLE_PATH, wavetable);

// For < 0V input, clamp to bottom note.
logic signed [W-1:0] lut_index;
logic [$clog2(V_OCT_LUT_SIZE)-1:0] lut_index_clamped;
logic [31:0] wavetable_pos = 32'h0;

assign lut_index = sample_in0 >>> 6;
assign lut_index_clamped = $clog2(V_OCT_LUT_SIZE)'(lut_index < 0 ? W'(0) : lut_index);

always_ff @(posedge sample_clk) begin
    // TODO: linear interpolation between frequencies, silence oscillator
    // whenever we are outside the LUT bounds.
    wavetable_pos <= wavetable_pos + 32'(v_oct_lut[lut_index_clamped]);
end

// Top 8 bits of the N.F fixed-point representation are index into wavetable.
localparam BIT_START = 10;
wire [$clog2(WAVETABLE_SIZE)-1:0] wavetable_idx =
    wavetable_pos[BIT_START+$clog2(WAVETABLE_SIZE)-1:BIT_START];
assign sample_out0 = wavetable[wavetable_idx];

endmodule
