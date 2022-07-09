module top (
    input CLK,   // 12mhz
    output P2_1, // scl
    output P2_2  // sda
);

reg [7:0] clkdiv;
reg clk_i2c_x2 = 1'b0;

always @(posedge CLK) begin
    clkdiv <= clkdiv + 1;
    if (clkdiv == 0) begin
        clk_i2c_x2 <= ~clk_i2c_x2;
    end
end

i2cinit i2cinit_instance (
    .clk (clk_i2c_x2),
    .scl (P2_1),
    .sda (P2_2)
);

endmodule
