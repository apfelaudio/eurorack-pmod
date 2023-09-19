// Module to drive a single `eurorack-pmod`. This can be instantiated
// multiple times for multiple PMODs if desired.
//
// Contains an instantiation of the I2C driver, calibration module
// and CODEC driver. Calibrated samples to/from this component are
// handled by external user-defined logic.

`default_nettype none

module eurorack_pmod #(
    parameter W = 16, // sample width, bits
    parameter CAL_MEM_FILE = "cal/cal_mem.hex",
    parameter CODEC_CFG_FILE  = "drivers/ak4619-cfg.hex",
    parameter LED_CFG_FILE  = "drivers/pca9635-cfg.hex"
)(
    input clk_256fs,
    input clk_fs,
    input rst,

    // Signals to/from eurorack-pmod hardware.
    //
    // Pin # referenced to iCEbreaker PMOD connector if NO ribbon
    // cable is used (i.e pins are not flipped).
	output i2c_scl_oe, // Pin 1 (tristate: 1 == LO, 0 == HiZ)
	input  i2c_scl_i,  // Pin 1 (tristate in)
	output i2c_sda_oe, // Pin 2 (tristate: 1 == LO, 0 == HiZ)
	input  i2c_sda_i,  // Pin 2 (tristate in)
    output pdn,        // Pin 3
    output mclk,       // Pin 4
    output sdin1,      // Pin 7
    input  sdout1,     // Pin 8
    output lrck,       // Pin 9
    output bick,       // Pin 10

    // Signals to exchange information to/from user-defined DSP core.
    //
    // Calibrated samples to/from CODEC at sample_clk.
    output signed [W-1:0] cal_in0,
    output signed [W-1:0] cal_in1,
    output signed [W-1:0] cal_in2,
    output signed [W-1:0] cal_in3,
    input signed [W-1:0] cal_out0,
    input signed [W-1:0] cal_out1,
    input signed [W-1:0] cal_out2,
    input signed [W-1:0] cal_out3,
    // EEPROM data read over I2C during startup.
    output [7:0] eeprom_mfg,
    output [7:0] eeprom_dev,
    output [31:0] eeprom_serial,
    // Jack detection inputs read constantly over I2C.
    // Logic '1' == jack is inserted. Bit 0 is input 0.
    output [7:0] jack,

    // Signals used for bringup / debug / calibration.
    //
    // Raw samples from the CODEC ADCs
    output signed [W-1:0] sample_adc0,
    output signed [W-1:0] sample_adc1,
    output signed [W-1:0] sample_adc2,
    output signed [W-1:0] sample_adc3,
    // Used for output calibration. If nonzero, all DAC outputs
    // are directly set to this value.
    input signed [W-1:0] force_dac_output
);

// Raw samples to/from CODEC
logic signed [W-1:0] sample_dac0;
logic signed [W-1:0] sample_dac1;
logic signed [W-1:0] sample_dac2;
logic signed [W-1:0] sample_dac3;

// Raw sample calibrator, both for input and output channels.
// Compensates for DC bias in CODEC, gain differences, resistor
// tolerances and so on.
cal #(
    .W(W),
    .CAL_MEM_FILE(CAL_MEM_FILE)
)cal_instance (
    .rst(rst),
    .clk_256fs (clk_256fs),
    .clk_fs (clk_fs),
    // Calibrated inputs are zeroed if jack is unplugged.
    .jack (jack),
    // Note: inputs samples are inverted by analog frontend
    // Should add +1 for precise 2s complement sign change
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

// CODEC ser-/deserialiser. Also derives sample clock.
ak4619 ak4619_instance (
    .clk_256fs     (clk_256fs),
    .clk_fs  (clk_fs),
    .rst     (rst),
    .pdn     (pdn),
    .mclk    (mclk),
    .bick    (bick),
    .lrck    (lrck),
    .sdin1   (sdin1),
    .sdout1  (sdout1),
    .sample_out0 (sample_adc0),
    .sample_out1 (sample_adc1),
    .sample_out2 (sample_adc2),
    .sample_out3 (sample_adc3),
    .sample_in0 (sample_dac0),
    .sample_in1 (sample_dac1),
    .sample_in2 (sample_dac2),
    .sample_in3 (sample_dac3)
);


// I2C transceiver and driver for all connected slaves.
pmod_i2c_master #(
    .CODEC_CFG(CODEC_CFG_FILE),
    .LED_CFG(LED_CFG_FILE)
) pmod_i2c_master_instance (
    .clk(clk_256fs),
    .rst(rst),

    .scl_oe(i2c_scl_oe),
    .scl_i(i2c_scl_i),
    .sda_oe(i2c_sda_oe),
    .sda_i(i2c_sda_i),

    // LEDs directly linked to input/output sample values
    // for now, although they could do whatever we want.
    .led0( cal_in0[W-1:W-8]),
    .led1( cal_in1[W-1:W-8]),
    .led2( cal_in2[W-1:W-8]),
    .led3( cal_in3[W-1:W-8]),
    .led4(force_dac_output == 0 ? cal_out0[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led5(force_dac_output == 0 ? cal_out1[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led6(force_dac_output == 0 ? cal_out2[W-1:W-8] : force_dac_output[W-1:W-8]),
    .led7(force_dac_output == 0 ? cal_out3[W-1:W-8] : force_dac_output[W-1:W-8]),

    .jack(jack),

    .eeprom_mfg_code(eeprom_mfg),
    .eeprom_dev_code(eeprom_dev),
    .eeprom_serial(eeprom_serial)
);

endmodule
