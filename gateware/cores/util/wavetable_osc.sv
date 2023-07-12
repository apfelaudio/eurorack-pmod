module wavetable_osc #(
    parameter W = 16,
    parameter WAVETABLE_PATH = "cores/util/vco/wavetable.hex",
    parameter WAVETABLE_SIZE = 256,
)(
    input rst,
    input sample_clk,
    input [31:0] wavetable_inc,
    output signed [W-1:0] out,
);

logic [W-1:0] wavetable [0:WAVETABLE_SIZE-1];
initial $readmemh(WAVETABLE_PATH, wavetable);

logic [31:0] wavetable_pos = 32'h0;

always_ff @(posedge sample_clk) begin
    // TODO: linear interpolation between frequencies, silence oscillator
    // whenever we are outside the LUT bounds.
    wavetable_pos <= wavetable_pos + wavetable_inc;
end

// Top 8 bits of the N.F fixed-point representation are index into wavetable.
localparam BIT_START = 10;
wire [$clog2(WAVETABLE_SIZE)-1:0] wavetable_idx =
    wavetable_pos[BIT_START+$clog2(WAVETABLE_SIZE)-1:BIT_START];

assign out = wavetable[wavetable_idx];

endmodule
