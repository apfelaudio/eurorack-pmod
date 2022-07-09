module top (
    input CLK,   // 12mhz
    output P2_1, // scl
    output P2_2  // sda
);

reg [7:0] clkdiv;
wire clk_i2c_x2 = clkdiv & 8'b10000000;

always @(posedge CLK) begin
    clkdiv <= clkdiv + 1;
end

i2cinit i2cinit_instance (
    clk_i2c_x2,
    P2_1,
    P2_2
);

endmodule
