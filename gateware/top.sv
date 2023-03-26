// Top-level module for using `eurorack-pmod` with Icebreaker FPGA.
//
// The defines below allow you to select calibration mode, spit samples out
// UART, or select one of the user-defined 'cores' (DSP modules).

`default_nettype none

// Transmit debug information over UART
`define DEBUG_UART

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

// Enable to flip PMOD pin mappings to fix pinout for an IDC ribbon.
`define EURORACK_PMOD_RIBBON_FLIP

module top #(
    parameter int W = 16 // sample width, bits
)(
     input   CLK // Assumed 12Mhz
`ifndef EURORACK_PMOD_RIBBON_FLIP
    ,output  P2_1
    ,inout   P2_2
    ,output  P2_3
    ,output  P2_4
    ,output  P2_7
    ,input   P2_8
    ,output  P2_9
    ,output  P2_10
`else
    ,output  P2_1
    ,input   P2_2
    ,output  P2_3
    ,output  P2_4
    ,output  P2_7
    ,inout   P2_8
    ,output  P2_9
    ,output  P2_10
`endif
`ifdef DEBUG_UART
    ,output TX
`endif
    ,input   BTN_N
);

logic rst;
logic clk_12mhz;
logic clk_24mhz; // Not currently used.

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

`ifdef DEBUG_UART
logic signed [W-1:0] pmod2_debug_adc0;
logic signed [W-1:0] pmod2_debug_adc1;
logic signed [W-1:0] pmod2_debug_adc2;
logic signed [W-1:0] pmod2_debug_adc3;
`endif

// PLL bringup and reset state management / debouncing.
ice40_sysmgr ice40_sysmgr_instance (
    .clk_in(CLK),
`ifndef OUTPUT_CALIBRATION
    // Normally, the uButton is used as a global reset button.
    .rst_in(~BTN_N),
`else
    // For output calibration the button is used elsewhere.
    .rst_in(1'b0),
`endif
    .clk_2x_out(clk_24mhz),
    .clk_1x_out(clk_12mhz),
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


// A `eurorack-pmod` connected to iCEbreaker PMOD2 port.
eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) eurorack_pmod2 (
    .clk_12mhz(clk_12mhz),
    .rst(rst),

`ifndef EURORACK_PMOD_RIBBON_FLIP
    // This pinout assumes a ribbon cable is NOT used and
    // the eurorack-pmod is connected directly to iCEbreaker.
    .i2c_scl(P2_1),
    .i2c_sda(P2_2),
    .pdn    (P2_3),
    .mclk   (P2_4),
    .sdin1  (P2_7),
    .sdout1 (P2_8),
    .lrck   (P2_9),
    .bick   (P2_10),
`else
    // Most 12-pin IDC ribbon cables will flip the pinout.
    // This pinout assumes a ribbon cable IS used.
    .i2c_scl(P2_7),
    .i2c_sda(P2_8),
    .pdn    (P2_9),
    .mclk   (P2_10),
    .sdin1  (P2_1),
    .sdout1 (P2_2),
    .lrck   (P2_3),
    .bick   (P2_4),
`endif

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
    .force_dac_output(BTN_N ? 20000 : -20000)
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
    .tx_o(TX),
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
