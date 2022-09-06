module sample (
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

assign sample_out0 = sample_in0 - 3500;
assign sample_out1 = sample_in1 - 3500;
assign sample_out2 = sample_in2 - 3500;
assign sample_out3 = sample_in3 - 3500;

endmodule
