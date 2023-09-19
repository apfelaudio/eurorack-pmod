// Top-level example module for using `eurorack-pmod`.

`default_nettype none

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

module top #(
    parameter int W = 16 // sample width, bits
)(
`ifndef INTERNAL_CLOCK
    input   CLK,
`endif
    inout   PMOD_I2C_SDA,
    inout   PMOD_I2C_SCL,
    output  PMOD_LRCK,
    output  PMOD_BICK,
    output  PMOD_SDIN1,
    input   PMOD_SDOUT1,
    output  PMOD_PDN,
    output  PMOD_MCLK,
    // Button used for reset and output cal. Assumed momentary, pressed == HIGH.
    // You can use any random PMOD that has a button on it.
    input   RESET_BUTTON,
    // UART used for debug information and for calibration.
    output  UART_TX
);

logic rst;
logic clk_256fs;
logic clk_fs; // FIXME: assign from PLL divider?

// Button signal is used for resets, unless we are input calibration
// mode in which case it is used for setting the output cal values.
logic button;
`ifdef INVERT_BUTTON
assign button = ~RESET_BUTTON;
`else
assign button = RESET_BUTTON;
`endif

// Signals between eurorack_pmod instance and user-defined DSP core.
logic signed [W-1:0] in0;
logic signed [W-1:0] in1;
logic signed [W-1:0] in2;
logic signed [W-1:0] in3;
logic signed [W-1:0] out0;
logic signed [W-1:0] out1;
logic signed [W-1:0] out2;
logic signed [W-1:0] out3;
logic [7:0]  eeprom_mfg;
logic [7:0]  eeprom_dev;
logic [31:0] eeprom_serial;
logic [7:0]  jack;

// Tristated I2C signals must be broken out at the top level as
// ECP5 flow does not support tristate signals in nested modules.
logic i2c_scl_oe;
logic i2c_scl_i;
logic i2c_sda_oe;
logic i2c_sda_i;

// Signals only used for the debug UART.
logic signed [W-1:0] debug_adc0;
logic signed [W-1:0] debug_adc1;
logic signed [W-1:0] debug_adc2;
logic signed [W-1:0] debug_adc3;

// PLL bringup and reset state management / debouncing.
sysmgr sysmgr_instance (
`ifndef INTERNAL_CLOCK
    // Warning: the input clock frequency might be different for different boards.
    // Make sure to adjust sysmgr / PLLs for your board as such.
    .clk_in(CLK),
`endif
`ifndef OUTPUT_CALIBRATION
    // Normally, the uButton is used as a global reset button.
    .rst_in(button),
`else
    // For output calibration the button is used elsewhere.
    .rst_in(1'b0),
`endif
    .clk_256fs(clk_256fs),
    .clk_fs(clk_fs),
    .rst_out(rst)
);

// DSP core which processes calibrated samples. This can be chosen
// by passing different DSP_CORE values to 'make' at build time.
`SELECTED_DSP_CORE #(
    .W(W)
) dsp_core_instance (
    .rst         (rst),
    .clk         (clk_256fs),
    .sample_clk  (clk_fs),
    .sample_in0  (in0),
    .sample_in1  (in1),
    .sample_in2  (in2),
    .sample_in3  (in3),
    .sample_out0 (out0),
    .sample_out1 (out1),
    .sample_out2 (out2),
    .sample_out3 (out3),
    .jack        (jack)
);

`ifdef ECP5
`ifndef VERILATOR_LINT_ONLY
// ECP5 requires direct IO block instantiation for tristating / I2C
TRELLIS_IO #(.DIR("BIDIR")) i2c_tristate_scl (
    .I(1'b0),
    .T(~i2c_scl_oe),
    .B(PMOD_I2C_SCL),
    .O(i2c_scl_i)
);
TRELLIS_IO #(.DIR("BIDIR")) i2c_tristate_sda (
    .I(1'b0),
    .T(~i2c_sda_oe),
    .B(PMOD_I2C_SDA),
    .O(i2c_sda_i)
);
`endif
`else
// For iCE40 this is not necessary.
assign PMOD_I2C_SCL = i2c_scl_oe ? 1'b0 : 1'bz;
assign PMOD_I2C_SDA = i2c_sda_oe ? 1'b0 : 1'bz;
assign i2c_scl_i = PMOD_I2C_SCL;
assign i2c_sda_i = PMOD_I2C_SDA;
`endif

eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) eurorack_pmod1 (
    .clk_256fs(clk_256fs),
    .clk_fs   (clk_fs),
    .rst(rst),

    .i2c_scl_oe(i2c_scl_oe),
    .i2c_scl_i (i2c_scl_i),
    .i2c_sda_oe(i2c_sda_oe),
    .i2c_sda_i (i2c_sda_i),
    .pdn    (PMOD_PDN),
    .mclk   (PMOD_MCLK),
    .sdin1  (PMOD_SDIN1),
    .sdout1 (PMOD_SDOUT1),
    .lrck   (PMOD_LRCK),
    .bick   (PMOD_BICK),

    .cal_in0      (in0),
    .cal_in1      (in1),
    .cal_in2      (in2),
    .cal_in3      (in3),
    .cal_out0     (out0),
    .cal_out1     (out1),
    .cal_out2     (out2),
    .cal_out3     (out3),
    .jack         (jack),
    .eeprom_mfg   (eeprom_mfg),
    .eeprom_dev   (eeprom_dev),
    .eeprom_serial(eeprom_serial),

    .sample_adc0(debug_adc0),
    .sample_adc1(debug_adc1),
    .sample_adc2(debug_adc2),
    .sample_adc3(debug_adc3),
`ifdef OUTPUT_CALIBRATION
    .force_dac_output(button ? -20000 : 20000)
`else
    .force_dac_output(0) // Do not force output.
`endif
);

// Helper module to serialize some interesting state to a UART
// for bringup and calibration purposes.
debug_uart #(
    .DIV(12) // WARN: baud rate is determined by clk_256fs / 12 !!
) debug_uart_instance (
    .clk (clk_256fs),
    .rst (rst),
    .tx_o(UART_TX),
    .adc0(debug_adc0),
    .adc1(debug_adc1),
    .adc2(debug_adc2),
    .adc3(debug_adc3),
    .eeprom_mfg(eeprom_mfg),
    .eeprom_dev(eeprom_dev),
    .eeprom_serial(eeprom_serial),
    .jack(jack)
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("top.vcd");
  $dumpvars;
  #1;
end
`endif


endmodule
