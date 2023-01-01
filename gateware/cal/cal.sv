// Calibrator module.
//
// Convert between raw & 'calibrated' samples by removing DC offset
// and scaling for 4 counts / mV (i.e 14.2 fixed-point).
//
// This is essentially implemented as a pipelined 8 channel multiplier
// with 4 channels used for calibrating raw ADC counts and 4 channels
// used for calibrating output DAC counts.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`. This module only uses a single multiplier for
// all channels such that there are plenty left over for user logic.

module cal (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] in0,
    input signed [15:0] in1,
    input signed [15:0] in2,
    input signed [15:0] in3,
    input signed [15:0] in4,
    input signed [15:0] in5,
    input signed [15:0] in6,
    input signed [15:0] in7,
    output signed [15:0] out0,
    output signed [15:0] out1,
    output signed [15:0] out2,
    output signed [15:0] out3,
    output signed [15:0] out4,
    output signed [15:0] out5,
    output signed [15:0] out6,
    output signed [15:0] out7
);

// Clamp cal_in to +/- 7V (28/4)
localparam CLAMP_HI = 28000;
localparam CLAMP_LO = -28000;

// Calibration memory for 8 channels stored as
// 2 bytes shift, 2 bytes multiply * 8 channels.
reg signed [15:0] cal_mem [0:15];
initial $readmemh("cal_mem.hex", cal_mem);

reg signed [15:0] adc_in_latched [0:7];

always @(posedge sample_clk) begin
    adc_in_latched[0] <= in0;
    adc_in_latched[1] <= in1;
    adc_in_latched[2] <= in2;
    adc_in_latched[3] <= in3;
    adc_in_latched[4] <= in4;
    adc_in_latched[5] <= in5;
    adc_in_latched[6] <= in6;
    adc_in_latched[7] <= in7;
end

// Source signal of calibration pipeline below so we only need 1 multiply
// for all 8 channels during 1 sample_clk.
wire signed [31:0] cal_unclamped = (
    (adc_in_latched[cur_channel] - cal_mem[{cur_channel, 1'b0}])
     * cal_mem[{cur_channel, 1'b1}]) >>> 10;

reg [2:0] cur_channel = 3'd0;
reg signed [15:0] outputs [0:7];

always @(posedge clk) begin
    if (CLAMP_HI < cal_unclamped && cal_unclamped < 16'h8000)
        outputs[cur_channel] <= CLAMP_HI;
    else if (16'h8000 <= cal_unclamped && cal_unclamped < CLAMP_LO)
        outputs[cur_channel] <= CLAMP_LO;
    else
        outputs[cur_channel] <= cal_unclamped;
    // FIXME: stop wrapping around after all channels updated..
    cur_channel <= cur_channel + 1;
end

assign out0 = outputs[0];
assign out1 = outputs[1];
assign out2 = outputs[2];
assign out3 = outputs[3];
assign out4 = outputs[4];
assign out5 = outputs[5];
assign out6 = outputs[6];
assign out7 = outputs[7];

endmodule
