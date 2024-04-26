// Driver for AK4619 CODEC.
//
// Usage:
// - `clk_256fs` determines the hardware sample rate.
// - Once CODEC is initialized over I2C, samples can be streamed.
// - `sample_in` is latched on `strobe`.
// - `sample_out` transitions on `strobe`.
//
// This core assumes the device is configured in the audio
// interface mode specified in ak4619-cfg.hex. This happens
// over I2C inside the state machine `pmod_i2c_master.sv`.
//
// The following registers specify the interface format:
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
    input  rst,
    input  clk_256fs,
    input  strobe,

    // Route these straight out to the CODEC pins.
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,

    // Transitions with `strobe`.
    output reg signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3,

    // Latches with `strobe`.
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3
);

localparam int N_CHANNELS = 4;

logic signed [(W*N_CHANNELS)-1:0] dac_words;
logic signed [W-1:0] adc_words [N_CHANNELS];

logic [7:0] clkdiv;

logic [1:0] channel;
logic [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clkdiv[0];
assign mclk        = clkdiv[0];
assign lrck        = clkdiv[7];

// 0, 1, 2, 3 == L, R, L, R
assign channel     = clkdiv[7:6];
// 0..31 for each channel, regardless of W.
assign bit_counter = clkdiv[5:1];

always_ff @(posedge clk_256fs) begin
    if (rst) begin
        sdin1 <= 0;
        clkdiv <= 0;
        adc_words[0] <= 0;
        adc_words[1] <= 0;
        adc_words[2] <= 0;
        adc_words[3] <= 0;
        dac_words <= 0;
    end else if (strobe) begin
        // Synchronize clkdiv to the incoming sample strobe, latching
        // our inputs and outputs in the clock cycle that `strobe` is high.
        clkdiv <= 8'h0;
        dac_words <= {sample_in3, sample_in2,
                      sample_in1, sample_in0};
        sample_out0  <= adc_words[0];
        sample_out1  <= adc_words[1];
        sample_out2  <= adc_words[2];
        sample_out3  <= adc_words[3];
        sdin1 <= dac_words[(1*W)-1];
    end else if (bick) begin
        // BICK transition HI -> LO: Clock in W bits
        // On HI -> LO both SDIN and SDOUT do not transition.
        // (determined by AK4619 transition polarity register BCKP)
        if (bit_counter < W) begin
            adc_words[channel][W - bit_counter - 1] <= sdout1;
        end
        clkdiv <= clkdiv + 1;
    end else begin // BICK: LO -> HI
        // BICK transition LO -> HI: Clock out W bits
        // On LO -> HI both SDIN and SDOUT transition.
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
        clkdiv <= clkdiv + 1;
    end
end


`ifdef COCOTB_SIM
`ifdef UNIT_TEST
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

// Shadow fake wires so we can look inside verilog arrays in vcd trace.
generate
  genvar idx;
  for(idx = 0; idx < N_CHANNELS; idx = idx+1) begin: register
    wire [W-1:0] adc_dummy;
    assign adc_dummy = adc_words[idx];
  end
endgenerate

`endif

endmodule
