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

assign sample_out0 = sample_in0;
assign sample_out1 = sample_in1;
assign sample_out2 = sample_in2;
assign sample_out3 = sample_in3;

/*
assign sample_out0 = 20000;
assign sample_out1 = 20000;
assign sample_out2 = 20000;
assign sample_out3 = 20000;
*/

endmodule
