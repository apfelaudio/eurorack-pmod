module top (
    input CLK,   // 12mhz
    output P2_1, // scl
    inout P2_2  // sda
);

reg [7:0] clkdiv;
reg clk_i2c_x2 = 1'b0;

always @(posedge CLK) begin
    clkdiv <= clkdiv + 1;
    if (clkdiv == 0) begin
        clk_i2c_x2 <= ~clk_i2c_x2;
    end
end

wire scl;
wire sda_out;
wire sda_in = 1'b1;
assign P2_1 = scl ? 1'bz : 1'b0;
assign P2_2 = sda_out ? 1'bz : 1'b0;

i2cinit i2cinit_instance (
    .clk (clk_i2c_x2),
    .scl (scl),
    .sda_out (sda_out),
    .sda_in (P2_2)
);

endmodule
