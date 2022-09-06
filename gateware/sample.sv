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

// Clamp inputs to +/- 6.5V (26/4)
localparam CLAMP_HI = 26000;
localparam CLAMP_LO = -26000;

reg signed [15:0] cal_mem [0:7];
initial $readmemh("cal_mem.hex", cal_mem);

reg signed [15:0] in_latched [0:3];
reg signed [15:0] in_calibrated [0:3];

reg [1:0] cur_channel = 2'd0;

always @(posedge sample_clk) begin
    in_latched[0] <= sample_in0;
    in_latched[1] <= sample_in1;
    in_latched[2] <= sample_in2;
    in_latched[3] <= sample_in3;
end

wire signed [31:0] cal_unclamped = (
    (in_latched[cur_channel] - cal_mem[cur_channel << 1])
     * cal_mem[(cur_channel << 1)+1]) >>> 8;

always @(posedge clk) begin
    if (CLAMP_HI < cal_unclamped && cal_unclamped < 16'h8000)
        in_calibrated[cur_channel] <= CLAMP_HI;
    else if (16'h8000 <= cal_unclamped && cal_unclamped < CLAMP_LO)
        in_calibrated[cur_channel] <= CLAMP_LO;
    else
        in_calibrated[cur_channel] <= cal_unclamped;
    cur_channel <= cur_channel + 1;
end

assign sample_out0 = in_calibrated[0];
assign sample_out1 = in_calibrated[1];
assign sample_out2 = in_calibrated[2];
assign sample_out3 = in_calibrated[3];

/*
assign sample_out0 = 16'hFF00;
assign sample_out1 = 16'hAF00;
assign sample_out2 = 16'hFF00;
assign sample_out3 = 16'hAF00;
*/

endmodule
