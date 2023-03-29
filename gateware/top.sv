// Top-level module for using `eurorack-pmod` with ECP5 // Colorlight i5.
//
// To change the DSP core which is used, modify the module type used
// by the `dsp_core_instance` entity below.

`default_nettype none

// Transmit debug information over UART
`define DEBUG_UART

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

module top #(
    parameter int W = 16 // sample width, bits
)(
     input   CLK // Assumed 25Mhz for Colorlight i5
    // This pinout assumes a ribbon cable IS used and the PMOD is
    // connected through an IDC ribbon to the dev board.
    ,inout   PMOD_P2A_IO5
    ,inout   PMOD_P2A_IO6
    ,output  PMOD_P2A_IO7
    ,output  PMOD_P2A_IO8
    ,output  PMOD_P2A_IO1
    ,input   PMOD_P2A_IO2
    ,output  PMOD_P2A_IO3
    ,output  PMOD_P2A_IO4
    // Button used for reset and output cal. Assumed momentary, pressed == HIGH.
    // You can use any random PMOD that has a button on it.
    ,input   PMOD_P2B_IO7
    // UART used for debug information and for calibration.
    ,output  UART_TX
);

logic rst;
logic clk_12mhz;

// Button signal to be used as a reset, unless we are in output 
logic button;
assign button = PMOD_P2B_IO7;

// Signals between eurorack_pmod instance and user-defined DSP core.
logic pmod2_sample_clk;
logic signed [W-1:0] pmod2_in0;
logic signed [W-1:0] pmod2_in1;
logic signed [W-1:0] pmod2_in2;
logic signed [W-1:0] pmod2_in3;
logic signed [W-1:0] pmod2_out0;
logic signed [W-1:0] pmod2_out1;
logic signed [W-1:0] pmod2_out2;
logic signed [W-1:0] pmod2_out3;
logic [7:0]  pmod2_eeprom_mfg;
logic [7:0]  pmod2_eeprom_dev;
logic [31:0] pmod2_eeprom_serial;
logic [7:0]  pmod2_jack;

// Tristated I2C signals must be broken out at the top level as
// ECP5 flow does not support tristate signals in nested modules.
logic pmod2_i2c_scl_oe;
logic pmod2_i2c_scl_i;
logic pmod2_i2c_sda_oe;
logic pmod2_i2c_sda_i;

`ifdef DEBUG_UART
logic signed [W-1:0] pmod2_debug_adc0;
logic signed [W-1:0] pmod2_debug_adc1;
logic signed [W-1:0] pmod2_debug_adc2;
logic signed [W-1:0] pmod2_debug_adc3;
`endif

// PLL bringup and reset state management / debouncing.
ecp5_sysmgr ecp5_sysmgr_instance (
    .clk_in(CLK),
`ifndef OUTPUT_CALIBRATION
    // Normally, the uButton is used as a global reset button.
    .rst_in(button),
`else
    // For output calibration the button is used elsewhere.
    .rst_in(1'b0),
`endif
    .clk_12m(clk_12mhz),
    .rst_out(rst)
);

// DSP core which processes calibrated samples. This can be
// modified or swapped out by one of the example cores.
mirror #( // 'mirror' just sends inputs straight to outputs.
    .W(W)
) pmod2_dsp_core_instance (
    .clk         (clk_12mhz),
    .sample_clk  (pmod2_sample_clk),
    .sample_in0  (pmod2_in0),
    .sample_in1  (pmod2_in1),
    .sample_in2  (pmod2_in2),
    .sample_in3  (pmod2_in3),
    .sample_out0 (pmod2_out0),
    .sample_out1 (pmod2_out1),
    .sample_out2 (pmod2_out2),
    .sample_out3 (pmod2_out3),
    .jack        (pmod2_jack)
);

TRELLIS_IO #(.DIR("BIDIR")) pmod2_i2c_tristate_scl (
    .I(1'b0),
    .T(~pmod2_i2c_scl_oe),
    .B(PMOD_P2A_IO1),
    .O(pmod2_i2c_scl_i)
);

TRELLIS_IO #(.DIR("BIDIR")) pmod2_i2c_tristate_sda (
    .I(1'b0),
    .T(~pmod2_i2c_sda_oe),
    .B(PMOD_P2A_IO2),
    .O(pmod2_i2c_sda_i)
);

// A `eurorack-pmod` connected to ColorLight PMOD2A port.
eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) eurorack_pmod2 (
    .clk_12mhz(clk_12mhz),
    .rst(rst),

    .i2c_scl_oe(pmod2_i2c_scl_oe),
    .i2c_scl_i (pmod2_i2c_scl_i),
    .i2c_sda_oe(pmod2_i2c_sda_oe),
    .i2c_sda_i (pmod2_i2c_sda_i),
    .pdn    (PMOD_P2A_IO3),
    .mclk   (PMOD_P2A_IO4),
    .sdin1  (PMOD_P2A_IO5),
    .sdout1 (PMOD_P2A_IO6),
    .lrck   (PMOD_P2A_IO7),
    .bick   (PMOD_P2A_IO8),

    .sample_clk   (pmod2_sample_clk),
    .cal_in0      (pmod2_in0),
    .cal_in1      (pmod2_in1),
    .cal_in2      (pmod2_in2),
    .cal_in3      (pmod2_in3),
    .cal_out0     (pmod2_out0),
    .cal_out1     (pmod2_out1),
    .cal_out2     (pmod2_out2),
    .cal_out3     (pmod2_out3),
    .jack         (pmod2_jack),
    .eeprom_mfg   (pmod2_eeprom_mfg),
    .eeprom_dev   (pmod2_eeprom_dev),
    .eeprom_serial(pmod2_eeprom_serial),

`ifdef DEBUG_UART
    .sample_adc0(pmod2_debug_adc0),
    .sample_adc1(pmod2_debug_adc1),
    .sample_adc2(pmod2_debug_adc2),
    .sample_adc3(pmod2_debug_adc3),
`ifdef OUTPUT_CALIBRATION
    .force_dac_output(button ? -20000 : 20000)
`else
    .force_dac_output(0) // Do not force output.
`endif
`else
    // Do not connect debug signals if debug UART disabled.
    .sample_adc0(),
    .sample_adc1(),
    .sample_adc2(),
    .sample_adc3(),
    .force_dac_output(0) // Do not force output.
`endif
);

`ifdef DEBUG_UART
// Helper module to serialize some interesting state to a UART
// for bringup and calibration purposes.
debug_uart debug_uart_instance (
    .clk (clk_12mhz),
    .rst (rst),
    .tx_o(UART_TX),
    .adc0(pmod2_debug_adc0),
    .adc1(pmod2_debug_adc1),
    .adc2(pmod2_debug_adc2),
    .adc3(pmod2_debug_adc3),
    .eeprom_mfg(pmod2_eeprom_mfg),
    .eeprom_dev(pmod2_eeprom_dev),
    .eeprom_serial(pmod2_eeprom_serial),
    .jack(pmod2_jack)
);
`endif

endmodule
