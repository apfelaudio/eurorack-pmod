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

wire sample_clk;
wire [15:0] sample_out0;
wire [15:0] sample_out1;
wire [15:0] sample_out2;
wire [15:0] sample_out3;
wire [15:0] sample_in0;
wire [15:0] sample_in1;
wire [15:0] sample_in2;
wire [15:0] sample_in3;

sample sample_instance (
    .sample_clk  (sample_clk),
    // Note: inputs samples are inverted by analog frontend
    // Should add +1 for precise 2s complement sign change
    .sample_in0 (~sample_out0),
    .sample_in1 (~sample_out1),
    .sample_in2 (~sample_out2),
    .sample_in3 (~sample_out3),
    .sample_out0 (sample_in0),
    .sample_out1 (sample_in1),
    .sample_out2 (sample_in2),
    .sample_out3 (sample_in3)
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
    .i2c_sda (P2_2),
    .sample_clk  (sample_clk),
    .sample_out0 (sample_out0),
    .sample_out1 (sample_out1),
    .sample_out2 (sample_out2),
    .sample_out3 (sample_out3),
    .sample_in0 (sample_in0),
    .sample_in1 (sample_in1),
    .sample_in2 (sample_in2),
    .sample_in3 (sample_in3)
);

endmodule
