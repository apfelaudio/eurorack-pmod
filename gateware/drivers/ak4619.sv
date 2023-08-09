// Driver for AK4619 ADC/DAC
//
// Currently assumes the device is configured in the audio
// interface mode specified in ak4619-cfg.hex.
//
// Currently 93.75KHz/16bit samples.

`default_nettype none

module ak4619 #(
    parameter W = 16 // sample width, bits
)(
    input  wire clk,   // Assumed 12MHz
    input  wire rst,
    output wire pdn,
    output wire mclk,
    output wire bick,
    output wire lrck,
    output reg sdin1,
    input  wire sdout1,

    output wire sample_clk,
    output reg signed [W-1:0] sample_out0,
    output reg signed [W-1:0] sample_out1,
    output reg signed [W-1:0] sample_out2,
    output reg signed [W-1:0] sample_out3,
    input  wire signed [W-1:0] sample_in0,
    input  wire signed [W-1:0] sample_in1,
    input  wire signed [W-1:0] sample_in2,
    input  wire signed [W-1:0] sample_in3
);

localparam N_CHANNELS = 4;

reg signed [(W*N_CHANNELS)-1:0] dac_words;
reg signed [W-1:0] adc_words [0:N_CHANNELS-1];

reg sdout1_latched    = 1'b0;
reg [7:0] clkdiv      = 8'd0;
wire [1:0] channel;
wire [4:0] bit_counter;

assign pdn         = ~rst;
assign bick        = clk;
assign mclk        = clk;
assign lrck        = clkdiv[6];   // 12MHz >> 7 == 93.75KHz

assign channel     = clkdiv[6:5]; // 0 == L (Ch0), 1 == R (Ch1)
assign bit_counter = clkdiv[4:0];
assign sample_clk  = lrck;

always @(negedge sample_clk) begin
    dac_words = {sample_in3, sample_in2,
                 sample_in1, sample_in0};
    sample_out0  <= adc_words[0];
    sample_out1  <= adc_words[1];
    sample_out2  <= adc_words[2];
    sample_out3  <= adc_words[3];
end

always @(negedge clk) begin
    // Clock out 16 bits
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
    // Clock in 16 bits
    if (bit_counter == 0) begin
        adc_words[channel] <= 0;
    end
    if (bit_counter <= W) begin
        adc_words[channel][W - bit_counter] <= sdout1_latched;
    end

    clkdiv <= clkdiv + 1;
end

always @(posedge clk) begin
    sdout1_latched <= sdout1;
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
