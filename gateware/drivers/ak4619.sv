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

logic signed [(W*N_CHANNELS)-1:0] dac_words;
logic signed [W-1:0] adc_words [N_CHANNELS];

logic [7:0] clkdiv;

logic [1:0] channel;
logic [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clkdiv[0];
assign mclk        = clk_256fs;
assign lrck        = clkdiv[7];

assign channel     = clkdiv[7:6]; // 0, 1, 2, 3 == L, R, L, R
assign bit_counter = clkdiv[5:1];

always_ff @(posedge clk_256fs) begin
    clkdiv <= clkdiv + 1;
    if (rst) begin
        clkdiv <= 8'h0;
        sample_out0  <= 0;
        sample_out1  <= 0;
        sample_out2  <= 0;
        sample_out3  <= 0;
    end else if (bick) begin // HI -> LO
        if (channel == (N_CHANNELS-1) && bit_counter == (2*W-1)) begin
            dac_words = {sample_in3, sample_in2,
                         sample_in1, sample_in0};
            sample_out0  <= adc_words[0];
            sample_out1  <= adc_words[1];
            sample_out2  <= adc_words[2];
            sample_out3  <= adc_words[3];
        end

        // Clock in W bits
        if (bit_counter == 0) begin
            adc_words[channel] <= 0;
        end
        if (bit_counter <= W) begin
            adc_words[channel][W - bit_counter - 1] <= sdout1;
        end
    end else begin
        // Clock out W bits
        if (bit_counter <= (W-1)) begin
            case (channel)
                0: sdin1 <= dac_words[(1*W)-1-bit_counter];
                1: sdin1 <= dac_words[(2*W)-1-bit_counter];
                2: sdin1 <= dac_words[(3*W)-1-bit_counter];
                3: sdin1 <= dac_words[(4*W)-1-bit_counter];
            endcase
        end else begin
            sdin1 <= 0;
        end
    end
end


endmodule
