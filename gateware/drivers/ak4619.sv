// Driver for AK4619 ADC/DAC
//
// Currently assumes the device is configured in the audio
// interface mode specified in ak4619-cfg.hex.
//
// The following registers are most important:
//  - FS == 0b000, which means:
//      - MCLK = 256*Fs,
//      - BICK = 128*Fs,
//      - Fs must fall within 8kHz <= Fs <= 48Khz.
// - TDM == 0b1 and DCF == 0b010, which means:
//      - TDM128 mode I2S compatible.
//

`default_nettype none

module ak4619 #(
    parameter W = 16 // sample width, bits
)(
    input  clk_256fs,
    input  clk_fs,

    input  rst,
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,

    output reg signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3,
    input  signed [W-1:0] sample_in0,
    input  signed [W-1:0] sample_in1,
    input  signed [W-1:0] sample_in2,
    input  signed [W-1:0] sample_in3
);

localparam int N_CHANNELS = 4;
localparam int TDM_W = 32;

logic signed [(TDM_W*N_CHANNELS)-1:0] dac_words;
logic signed [(TDM_W*N_CHANNELS)-1:0] adc_words;

logic [7:0] clkdiv;
logic [1:0] channel;
logic [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clkdiv[0];
assign mclk        = clk_256fs;
assign lrck        = clkdiv[7];

assign channel     = clkdiv[7:6]; // 0, 1, 2, 3 == L, R, L, R
assign bit_counter = (TDM_W-1)-clkdiv[5:1];

always_ff @(negedge clk_fs) begin
    dac_words[(TDM_W*1)-1:(TDM_W*0)] <= {sample_in0, 16'd0};
    dac_words[(TDM_W*2)-1:(TDM_W*1)] <= {sample_in1, 16'd0};
    dac_words[(TDM_W*3)-1:(TDM_W*2)] <= {sample_in2, 16'd0};
    dac_words[(TDM_W*4)-1:(TDM_W*3)] <= {sample_in3, 16'd0};
    sample_out0 <= adc_words[TDM_W*1:(TDM_W*1)-W];
    sample_out1 <= adc_words[TDM_W*2:(TDM_W*2)-W];
    sample_out2 <= adc_words[TDM_W*3:(TDM_W*3)-W];
    sample_out3 <= adc_words[TDM_W*4:(TDM_W*4)-W];
end

always_ff @(posedge clk_256fs) begin
    clkdiv <= clkdiv + 1;
    if (rst) begin
        clkdiv <= 8'h0;
    end else if (bick) begin // HI -> LO
        adc_words[{channel, bit_counter}] <= sdout1;
    end else begin
        sdin1 <= dac_words[{channel, bit_counter}];
    end
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
