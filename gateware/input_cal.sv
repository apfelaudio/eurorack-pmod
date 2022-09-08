module input_cal (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] adc_in0,
    input signed [15:0] adc_in1,
    input signed [15:0] adc_in2,
    input signed [15:0] adc_in3,
    output signed [15:0] cal_in0,
    output signed [15:0] cal_in1,
    output signed [15:0] cal_in2,
    output signed [15:0] cal_in3
);

// Clamp al_out to +/- 7V (28/4)
localparam CLAMP_HI = 28000;
localparam CLAMP_LO = -28000;

// Calibration memory for 4 channels stored as
// 2 bytes shift, 2 bytes multiply * 4 channels.
reg signed [15:0] cal_mem [0:7];
initial $readmemh("input_cal_mem.hex", cal_mem);

reg signed [15:0] adc_in_latched [0:3];

always @(posedge sample_clk) begin
    adc_in_latched[0] <= adc_in0;
    adc_in_latched[1] <= adc_in1;
    adc_in_latched[2] <= adc_in2;
    adc_in_latched[3] <= adc_in3;
end

// Source signal of calibration pipeline below so we only need 1 multiply
// for all 4 channels during 1 sample_clk.
wire signed [31:0] cal_unclamped = (
    (adc_in_latched[cur_channel] - cal_mem[{cur_channel, 1'b0}])
     * cal_mem[{cur_channel, 1'b1}]) >>> 10;

reg [1:0] cur_channel = 2'd0;
reg signed [15:0] cal_in [0:3];

always @(posedge clk) begin
    if (CLAMP_HI < cal_unclamped && cal_unclamped < 16'h8000)
        cal_in[cur_channel] <= CLAMP_HI;
    else if (16'h8000 <= cal_unclamped && cal_unclamped < CLAMP_LO)
        cal_in[cur_channel] <= CLAMP_LO;
    else
        cal_in[cur_channel] <= cal_unclamped;
    // FIXME: stop wrapping around after all channels updated..
    cur_channel <= cur_channel + 1;
end

assign cal_in0 = cal_in[0];
assign cal_in1 = cal_in[1];
assign cal_in2 = cal_in[2];
assign cal_in3 = cal_in[3];

endmodule
