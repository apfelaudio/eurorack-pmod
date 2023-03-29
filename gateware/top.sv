// Top-level module for using `eurorack-pmod` with Icebreaker FPGA.
//
// To change the DSP core which is used, modify the module type used
// by the `dsp_core_instance` entity below.

`default_nettype none

// Transmit debug information over UART
//`define DEBUG_UART

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

module top #(
    parameter int W = 16 // sample width, bits
)(
     input   CLK // Assumed 12Mhz
    // This pinout assumes a ribbon cable is NOT used and
    // the eurorack-pmod is connected directly to ColorLight dev board.
    ,inout   PMOD_P2A_IO5
    ,inout   PMOD_P2A_IO6
    ,output  PMOD_P2A_IO7
    ,output  PMOD_P2A_IO8
    ,output  PMOD_P2A_IO1
    ,input   PMOD_P2A_IO2
    ,output  PMOD_P2A_IO3
    ,output  PMOD_P2A_IO4
`ifdef DEBUG_UART
    ,output TX
`endif
    //,input   BTN_N
);

logic [15:0] startup_delay = 0;
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
/*
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
*/

always @(posedge CLK) begin
    clk_12mhz <= ~clk_12mhz;
    if (startup_delay < 16'hF000) begin
        startup_delay <= startup_delay + 1;
        // We have to emit a reset on startup for some
        // components to initialize correctly!.
        rst <= 1'b1;
    end else begin
        rst <= 1'b0;
    end
end

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

logic i2c_scl_oe;
logic i2c_scl_i;
logic i2c_sda_oe;
logic i2c_sda_i;

TRELLIS_IO #(.DIR("BIDIR")) i2c_tristate_scl (
    .I(1'b0),
    .T(~i2c_scl_oe),
    .B(PMOD_P2A_IO1),
    .O(i2c_scl_i)
);

TRELLIS_IO #(.DIR("BIDIR")) i2c_tristate_sda (
    .I(1'b0),
    .T(~i2c_sda_oe),
    .B(PMOD_P2A_IO2),
    .O(i2c_sda_i)
);

// A `eurorack-pmod` connected to ColorLight PMOD2A port.
eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) eurorack_pmod2 (
    .clk_12mhz(clk_12mhz),
    .rst(rst),

    .i2c_scl_oe(i2c_scl_oe),
    .i2c_scl_i (i2c_scl_i),
    .i2c_sda_oe(i2c_sda_oe),
    .i2c_sda_i (i2c_sda_i),
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
