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

//assign sdout1 = 1'b1;


reg [7:0] clkdiv = 8'd0;
always @(posedge clk) begin
    clkdiv <= clkdiv + 1;
end

assign bick = clkdiv[1];
assign lrck = clkdiv[7];

reg [15:0] dac_out_word = 16'hAF00;
reg [15:0] adc_word  = 16'h0;
reg [15:0] adc_word2 = 16'h0;

always @(posedge lrck) begin
    dac_out_word <= adc_word + adc_word2;
end

wire [4:0] bit_counter = clkdiv[6:2];
wire ch_ix = clkdiv[7];
always @(posedge bick) begin
    if (bit_counter <= 4'hF) begin
        if (ch_ix == 0) begin
            sdin1 <= dac_out_word[4'hF - bit_counter];
            if (bit_counter == 6'd1) begin
                adc_word <= 16'h0;
            end else begin
                adc_word[(4'hF - bit_counter) + 2] <= sdout1_latched;
            end
        end else begin
            if (bit_counter == 6'd1) begin
                adc_word2 <= 16'h0;
            end else begin
                adc_word2[(4'hF - bit_counter) + 2] <= sdout1_latched;
            end
        end
    end else begin
        sdin1 <= 0;
    end
end

reg sdout1_latched = 1'b0;
always @(negedge bick) begin
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
