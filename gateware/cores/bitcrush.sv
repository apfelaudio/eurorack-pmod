// Bit Crusher
//
// Reduce number of bits on channels 1-3 according to the voltage
// on channel 0.
//
// Mapping:
// - Input 0: Bitcrusher mask setting (0-5V)
// - Input 1-3: Audio inputs
// - Output 0: Input 0 (mirrored)
// - Output 1-3: Audio outputs (bitcrushed)

module bitcrush #(
    parameter W = 16
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

logic signed [W-1:0] mask;
logic signed [W-1:0] out1;
logic signed [W-1:0] out2;
logic signed [W-1:0] out3;

assign mask = (sample_in0 > 4*5000) ? 16'b1111111111111111 :
              (sample_in0 > 4*4500) ? 16'b1111111111100000 :
              (sample_in0 > 4*4000) ? 16'b1111111111000000 :
              (sample_in0 > 4*3500) ? 16'b1111111110000000 :
              (sample_in0 > 4*3000) ? 16'b1111111100000000 :
              (sample_in0 > 4*2500) ? 16'b1111111000000000 :
              (sample_in0 > 4*2000) ? 16'b1111110000000000 :
              (sample_in0 > 4*1500) ? 16'b1111100000000000 :
              (sample_in0 > 4*1000) ? 16'b1111000000000000 :
              (sample_in0 > 4* 500) ? 16'b1110000000000000 :
                                      16'b1100000000000000;

always_ff @(posedge sample_clk) begin
    out1 <= sample_in1 & mask;
    out2 <= sample_in2 & mask;
    out3 <= sample_in3 & mask;
end

assign sample_out0 = sample_in0;
assign sample_out1 = out1;
assign sample_out2 = out2;
assign sample_out3 = out3;

endmodule
