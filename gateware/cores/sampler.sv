// Sample player.
//
// Given an input trigger on input 0, play converted .wav sample on output 0.
//
// At the moment this is VERY simple and uses a hex file put straight into the FPGA
// RAM, but it should be pretty easy to store it in the SPI flash (which
// has a lot more space).
//
// Mapping:
// - Input 0: Trigger input
// - Output 0: Sample audio output

module sampler (
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

`define FROM_MV(value) (value <<< 2)

// Input trigger voltage thresholds.
`define TRIGGER_HI `FROM_MV(1000)

// RAM containing the sample itself
parameter N_SAMPLES = 16'h690;
reg [15:0] wav_samples [0:N_SAMPLES];
initial $readmemh("sampler_data/clap.hex", wav_samples);


// Playback speed is a bit slower than sample_clk.
reg [15:0] sclkdiv = 16'h0;
// Current index in the sample we are playing.
reg [15:0] sample_pos = 16'h0;
// Value of the last sample at sample_pos, synchronized to sample_clk.
reg [15:0] cur_sample = 16'h0;

always @(posedge sample_clk) begin
    sclkdiv <= sclkdiv + 1;
    if (sclkdiv % 2 == 0 && sample_pos <= N_SAMPLES) begin
        sample_pos <= sample_pos + 1;
    end
    if (sample_in0 < `TRIGGER_HI) begin
        // Hold first sample as long as we have no trigger. As
        // soon as it goes high, we 'allow' playback.
        sample_pos <= 0;
    end
    if (sample_pos < N_SAMPLES) begin
        cur_sample <= wav_samples[sample_pos];
    end else begin
        // If we go past the end of the sample, hold 0V at the output.
        cur_sample <= 16'h0;
    end
end



assign sample_out0 = cur_sample;

assign sample_out1 = sample_in1;
assign sample_out2 = sample_in2;
assign sample_out3 = sample_in3;

endmodule
