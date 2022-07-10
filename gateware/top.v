module top (
    input CLK,   // 12mhz
    output P2_1, // SCL
    inout P2_2,  // SDA
    output P2_3  // PDN
);

reg [7:0] clkdiv = 8'd1;
reg clk_i2c_x2 = 1'b0;
reg pdn_out = 1'b0;

always @(posedge CLK) begin
    clkdiv <= clkdiv + 1;
    if (clkdiv == 0) begin
        clk_i2c_x2 <= ~clk_i2c_x2;
        pdn_out <= 1'b1;
    end
end

wire scl;
wire sda_out;
wire sda_in = 1'b1;
assign P2_1 = scl ? 1'bz : 1'b0;
assign P2_2 = sda_out ? 1'bz : 1'b0;
assign P2_3 = pdn_out;


i2cinit i2cinit_instance (
    .clk (clk_i2c_x2),
    .scl (scl),
    .sda_out (sda_out),
    .sda_in (P2_2)
);

endmodule
