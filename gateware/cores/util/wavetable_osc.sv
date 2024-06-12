module wavetable_osc #(
    parameter W = 16,
    parameter FRAC_BITS = 10,
    parameter WAVETABLE_PATH = "cores/util/vco/wavetable.hex",
    parameter WAVETABLE_SIZE = 256
)(
    input rst,
    input clk,
    input strobe,
    input [31:0] wavetable_inc,
    output logic signed [W-1:0] out
);

logic [W-1:0] wavetable [0:WAVETABLE_SIZE-1];
initial $readmemh(WAVETABLE_PATH, wavetable);

// Position in wavetable - N.F fixed-point where BIT_START is size of F.
logic [31:0] wavetable_pos = 0;

always_ff @(posedge clk) begin
    if (strobe) begin
        if (rst) begin
            wavetable_pos <= 0;
        end else begin
            wavetable_pos <= wavetable_pos + wavetable_inc;
            // Take top N bits of wavetable_pos as output.
            out <= wavetable[wavetable_pos[FRAC_BITS+$clog2(WAVETABLE_SIZE)-1:FRAC_BITS]];
        end
    end
end

endmodule
