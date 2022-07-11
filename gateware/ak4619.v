module ak4619 (
    input  clk,   // Assumed 12MHz
    output pdn,
    output mclk,
    output bick,
    output lrck,
    output reg sdin1,
    input  sdout1,
    output i2c_scl,
    inout  i2c_sda
);

assign pdn = 1'b1;
assign mclk = clk;

wire scl_i2cinit;
wire sda_out_i2cinit;
assign i2c_scl = scl_i2cinit ? 1'bz : 1'b0;
assign i2c_sda = sda_out_i2cinit ? 1'bz : 1'b0;


reg [7:0] clkdiv = 8'd0;
always @(posedge clk) begin
    clkdiv <= clkdiv + 1;
end

assign bick = clkdiv[1]; // 12MHz >> 2 == 3MHz
assign lrck = clkdiv[7]; // 12MHz >> 8 == 46.875KHz

reg [15:0] dac_words [0:1];
reg [15:0] adc_words [0:1];

always @(posedge lrck) begin
    dac_words[0] <= adc_words[0];
    dac_words[1] <= adc_words[1];
end

wire channel = lrck; // 0 == L (Ch0), 1 == R (Ch1)
reg [4:0] bit_counter = 8'h0;
always @(negedge bick) begin
    bit_counter <= bit_counter + 1;
    if (bit_counter > 5'hF) begin
        sdin1 <= 0;
    end else begin
        sdin1 <= dac_words[channel][5'hF - bit_counter];
        if (bit_counter == 5'h0) begin
            adc_words[channel] <= {sdout1_latched, 15'h0};
        end else begin
            adc_words[channel][(5'hF - bit_counter) + 1] <= sdout1_latched;
        end
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
