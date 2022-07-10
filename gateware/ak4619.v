module ak4619 (
    input  clk,   // Assumed 12MHz
    output pdn,
    output mclk,
    output reg bick,
    output reg lrck,
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
    bick <= clkdiv[1];
    lrck <= clkdiv[7];
end


reg [15:0] dac_out_word = 16'd0;
reg [3:0] dac_out_shift = 4'h0;
always @(posedge lrck) begin
    dac_out_word <= dac_out_word + 4'h8;
end

reg prev_lrck = 1'b0;
always @(negedge bick) begin
    if (prev_lrck != lrck) begin
        dac_out_shift <= 0;
    end
    if (dac_out_shift != 4'hF) begin
        dac_out_shift <= dac_out_shift + 1;
        sdin1 <= 1'b1 & (dac_out_word >> (4'hF - dac_out_shift));
    end else begin
        sdin1 <= 0;
    end
    prev_lrck <= lrck;
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
