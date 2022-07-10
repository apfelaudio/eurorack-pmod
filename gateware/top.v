module top (
    input CLK,    // 12mhz
    output P2_1,  // SCL
    inout P2_2,   // SDA
    output P2_3,  // PDN
    output P2_4,  // MCLK
    output P2_7,   // SDIN1
    input P2_8,  // SDOUT1
    output P2_9,  // LRCK
    output P2_10  // BICK
);

reg [7:0] clkdiv = 8'd1;
reg clk_i2c_x2 = 1'b0;
reg pdn_out = 1'b1;

reg lrck = 1'b0;
reg bick = 1'b0;

always @(posedge CLK) begin
    clkdiv <= clkdiv + 1;
    clk_i2c_x2 <= clkdiv[7];
    bick <= clkdiv[1];
    lrck <= clkdiv[7];
end


reg [15:0] out_val = 16'd0;
reg [3:0] shift = 4'h0;
always @(posedge lrck) begin
    out_val <= out_val + 4'h8;
end

reg sdin1 = 1'b0;
reg prev_lrck = 1'b0;
always @(negedge bick) begin
    if (prev_lrck != lrck) begin
        shift <= 0;
    end
    if (shift != 4'hF) begin
        shift <= shift + 1;
        sdin1 <= 1'b1 & (out_val >> (4'hF - shift));
    end else begin
        sdin1 <= 0;
    end
    prev_lrck <= lrck;
end

wire scl;
wire sda_out;
wire sda_in = 1'b1;
assign P2_1 = scl ? 1'bz : 1'b0;
assign P2_2 = sda_out ? 1'bz : 1'b0;
assign P2_3 = pdn_out;

assign P2_4 = CLK;
assign P2_9 = lrck;
assign P2_10 = bick;

assign P2_7 = sdin1;


i2cinit i2cinit_instance (
    .clk (clk_i2c_x2),
    .scl (scl),
    .sda_out (sda_out),
    .sda_in (P2_2)
);

endmodule
