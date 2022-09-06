module sample (
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

// Clamp inputs to +/- 6.5V (26/4)
localparam CLAMP_HI = 26000;
localparam CLAMP_LO = -26000;

reg [15:0] in0 = 16'h8000;
wire [31:0] in0_unclamped = ((sample_in0 - 16'sd4122) * 32'sd269) >>> 8;

always @(posedge sample_clk) begin
    if (CLAMP_HI < in0_unclamped && in0_unclamped < 16'h8000) in0 <= CLAMP_HI;
    else if (16'h8000 <= in0_unclamped && in0_unclamped < CLAMP_LO) in0 <= CLAMP_LO;
    else in0 <= in0_unclamped;
end


assign sample_out0 = in0;
assign sample_out1 = sample_in1;
assign sample_out2 = sample_in2;
assign sample_out3 = sample_in3;

/*
assign sample_out0 = 16'hFF00;
assign sample_out1 = 16'hAF00;
assign sample_out2 = 16'hFF00;
assign sample_out3 = 16'hAF00;
*/

endmodule
