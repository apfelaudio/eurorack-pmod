module sample (
    input sample_clk,
    input signed [15:0] sample_in0,
    input signed [15:0] sample_in1,
    output signed [15:0] sample_out0,
    output signed [15:0] sample_out1
);

assign sample_out0 = sample_in0;
assign sample_out1 = sample_in1;

endmodule
