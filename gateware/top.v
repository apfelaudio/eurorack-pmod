module top (
    input   CLK,
    output  P2_1,
    inout   P2_2,
    output  P2_3,
    output  P2_4,
    output  P2_7,
    input   P2_8,
    output  P2_9,
    output  P2_10
);

ak4619 ak4619_instance (
    .clk     (CLK),
    .pdn     (P2_3),
    .mclk    (P2_4),
    .bick    (P2_10),
    .lrck    (P2_9),
    .sdin1   (P2_7),
    .sdout1  (P2_8),
    .i2c_scl (P2_1),
    .i2c_sda (P2_2)
);

endmodule
