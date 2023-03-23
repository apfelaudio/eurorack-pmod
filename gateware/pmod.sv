`default_nettype none

module pmod #(
    parameter W = 16
)(
    input rst,
    input clk_12mhz,

    output i2c_scl,
    inout i2c_sda,
    output pdn,
    output mclk,
    output sdin1,
    input sdout1,
    output lrck,
    output bick
);

logic sample_clk;

// Raw samples to/from CODEC
logic signed [W-1:0] sample_adc0;
logic signed [W-1:0] sample_adc1;
logic signed [W-1:0] sample_adc2;
logic signed [W-1:0] sample_adc3;
logic signed [W-1:0] sample_dac0;
logic signed [W-1:0] sample_dac1;
logic signed [W-1:0] sample_dac2;
logic signed [W-1:0] sample_dac3;

// Calibrated samples to/from CODEC
logic signed [W-1:0] cal_in0;
logic signed [W-1:0] cal_in1;
logic signed [W-1:0] cal_in2;
logic signed [W-1:0] cal_in3;
logic signed [W-1:0] cal_out0;
logic signed [W-1:0] cal_out1;
logic signed [W-1:0] cal_out2;
logic signed [W-1:0] cal_out3;

logic [7:0] jack;
logic [7:0] eeprom_mfg;
logic [7:0] eeprom_dev;
logic [31:0] eeprom_serial;

seqswitch core_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3),
    .jack(jack)
);

cal cal_instance (
    .clk (clk_12mhz),
    .sample_clk (sample_clk),
    .jack (jack),
    .in0 (~sample_adc0),
    .in1 (~sample_adc1),
    .in2 (~sample_adc2),
    .in3 (~sample_adc3),
    .in4 (cal_out0),
    .in5 (cal_out1),
    .in6 (cal_out2),
    .in7 (cal_out3),
    .out0 (cal_in0),
    .out1 (cal_in1),
    .out2 (cal_in2),
    .out3 (cal_in3),
    .out4 (sample_dac0),
    .out5 (sample_dac1),
    .out6 (sample_dac2),
    .out7 (sample_dac3)
);

ak4619 ak4619_instance (
    .clk     (clk_12mhz),
    .rst     (rst),
    .pdn     (pdn),
    .mclk    (mclk),
    .bick    (bick),
    .lrck    (lrck),
    .sdin1   (sdin1),
    .sdout1  (sdout1),
    .sample_clk  (sample_clk),
    .sample_out0 (sample_adc0),
    .sample_out1 (sample_adc1),
    .sample_out2 (sample_adc2),
    .sample_out3 (sample_adc3),
    .sample_in0 (sample_dac0),
    .sample_in1 (sample_dac1),
    .sample_in2 (sample_dac2),
    .sample_in3 (sample_dac3)
);

logic i2c_scl_oe;
logic i2c_sda_oe;

// TODO: switch to explicit tristating IO blocks for this so
// Yosys throws blocking errors if the flow doesn't support it.
assign i2c_scl = i2c_scl_oe ? 1'b0 : 1'bz;
assign i2c_sda = i2c_sda_oe ? 1'b0 : 1'bz;

pmod_i2c_master pmod_i2c_master_instance (
    .clk(clk_12mhz),
    .rst(rst),

    .scl_oe(i2c_scl_oe),
    .scl_i(i2c_scl),
    .sda_oe(i2c_sda_oe),
    .sda_i(i2c_sda),

    .led0( cal_in0[W-1:W-8]),
    .led1( cal_in1[W-1:W-8]),
    .led2( cal_in2[W-1:W-8]),
    .led3( cal_in3[W-1:W-8]),
    .led4(cal_out0[W-1:W-8]),
    .led5(cal_out1[W-1:W-8]),
    .led6(cal_out2[W-1:W-8]),
    .led7(cal_out3[W-1:W-8]),

    .jack(jack),

    .eeprom_mfg_code(eeprom_mfg),
    .eeprom_dev_code(eeprom_dev),
    .eeprom_serial(eeprom_serial)
);

endmodule
