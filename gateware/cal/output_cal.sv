// TODO: basically the same logic as the input calibrator.
// See docs for input calibrator. It should be trivial to combine them.

module output_cal (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] cal_out0,
    input signed [15:0] cal_out1,
    input signed [15:0] cal_out2,
    input signed [15:0] cal_out3,
    output signed [15:0] dac_out0,
    output signed [15:0] dac_out1,
    output signed [15:0] dac_out2,
    output signed [15:0] dac_out3
);

// Clamp dac_outX to 16 bits (it multiplies out to 32 bits).
localparam CLAMP_HI = 32000;
localparam CLAMP_LO = -32000;

// Calibration memory for 4 channels stored as
// 2 bytes shift, 2 bytes multiply * 4 channels.
reg signed [15:0] cal_mem [0:7];
initial $readmemh("output_cal_mem.hex", cal_mem);

reg signed [15:0] cal_out_latched [0:3];

always @(posedge sample_clk) begin
    cal_out_latched[0] <= cal_out0;
    cal_out_latched[1] <= cal_out1;
    cal_out_latched[2] <= cal_out2;
    cal_out_latched[3] <= cal_out3;
end

// Source signal of calibration pipeline below so we only need 1 multiply
// for all 4 channels during 1 sample_clk.
wire signed [31:0] dac_unclamped = (
    (cal_out_latched[cur_channel] - cal_mem[{cur_channel, 1'b0}])
     * cal_mem[{cur_channel, 1'b1}]) >>> 10;

reg [1:0] cur_channel = 2'd0;
reg signed [15:0] dac_out [0:3];

always @(posedge clk) begin
    if (CLAMP_HI < dac_unclamped && dac_unclamped < 16'h8000)
        dac_out[cur_channel] <= CLAMP_HI;
    else if (16'h8000 <= dac_unclamped && dac_unclamped < CLAMP_LO)
        dac_out[cur_channel] <= CLAMP_LO;
    else
        dac_out[cur_channel] <= dac_unclamped;
    // FIXME: stop wrapping around after all channels updated.
    cur_channel <= cur_channel + 1;
end

assign dac_out0 = dac_out[0];
assign dac_out1 = dac_out[1];
assign dac_out2 = dac_out[2];
assign dac_out3 = dac_out[3];

endmodule
