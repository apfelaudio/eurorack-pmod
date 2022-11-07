module shifter (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] sample_in0,
    input signed [15:0] sample_in1,
    input signed [15:0] sample_in2,
    input signed [15:0] sample_in3,
    output signed [15:0] sample_out0,
    output signed [15:0] sample_out1,
    output signed [15:0] sample_out2,
    output signed [15:0] sample_out3
);

// Calibrated samples represent millivolts in 16 bits, last 2 bits are fractional.
`define FROM_MV(value) (value <<< 2)

reg signed [15:0] out_ch1;
reg signed [15:0] out_ch2;

wire in0_div = sample_in0 >>> 7;
wire in0_abs = in0_div > 0 ? in0_div : 0;

always @(posedge sample_clk) begin
    out_ch1 <= in0_abs * (sample_in1 >>> 8);
    out_ch2 <= in0_abs * (sample_in2 >>> 8);
end

assign sample_out0 = sample_in0;
assign sample_out1 = out_ch1;
assign sample_out2 = out_ch2;
assign sample_out3 = 16'h0;

endmodule
