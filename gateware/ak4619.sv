module ak4619 (
    input  clk,   // Assumed 12MHz
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,
    output i2c_scl,
    inout  i2c_sda,

    output reg sample_clk,
    output signed [15:0] sample_out0,
    output signed [15:0] sample_out1,
    output signed [15:0] sample_out2,
    output signed [15:0] sample_out3,
    input signed [15:0] sample_in0,
    input signed [15:0] sample_in1,
    input signed [15:0] sample_in2,
    input signed [15:0] sample_in3
);

assign pdn = 1'b1;

wire scl_i2cinit;
wire sda_out_i2cinit;
assign i2c_scl = scl_i2cinit ? 1'bz : 1'b0;
assign i2c_sda = sda_out_i2cinit ? 1'bz : 1'b0;


assign bick = clk;
assign mclk = clk;
assign lrck = clkdiv[6]; // 12MHz >> 7 == 93.75KHz


reg signed [15:0] dac_words [0:3];
reg signed [15:0] adc_words [0:3];
assign sample_out0 = adc_words[0];
assign sample_out1 = adc_words[1];
assign sample_out2 = adc_words[2];
assign sample_out3 = adc_words[3];


reg [7:0] clkdiv = 8'd0;
wire [1:0] channel = clkdiv[6:5]; // 0 == L (Ch0), 1 == R (Ch1)
wire [4:0] bit_counter = clkdiv[4:0];
always @(negedge bick) begin
    clkdiv <= clkdiv + 1;
    // Clock out 16 bits
    if (bit_counter <= 5'hF) begin
        sdin1 <= dac_words[channel][5'hF - bit_counter];
    end else begin
        sdin1 <= 0;
    end
    // Clock in 16 bits
    if (bit_counter == 5'h0) begin
        adc_words[channel] <= 16'h0;
    end
    if (bit_counter <= 5'h10) begin
        adc_words[channel][5'h10 - bit_counter] <= sdout1_latched;
    end
    if (bit_counter == 5'h11 && channel == 2'h3) begin
        dac_words[0] <= sample_in0;
        dac_words[1] <= sample_in1;
        dac_words[2] <= sample_in2;
        dac_words[3] <= sample_in3;
        sample_clk <= 0;
    end
    if (bit_counter == 5'h11 && channel == 2'h1) begin
        // Here is where samples should be clocked in/out.
        sample_clk <= 1;
    end
end

reg sdout1_latched = 1'b0;
always @(posedge bick) begin
    sdout1_latched <= sdout1;
end

i2cinit i2cinit_instance (
    .clk (lrck),
    .scl (scl_i2cinit),
    .sda_out (sda_out_i2cinit)
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("ak4619.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
