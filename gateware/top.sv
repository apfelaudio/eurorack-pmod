// Top-level example module for using `eurorack-pmod`.

`default_nettype none

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

module top #(
    parameter int W = 16 // sample width, bits
)(
     input   CLK

    ,inout   PMOD_P2A_I2C_SDA
    ,inout   PMOD_P2A_I2C_SCL
    ,output  PMOD_P2A_LRCK
    ,output  PMOD_P2A_BICK
    ,output  PMOD_P2A_SDIN1
    ,input   PMOD_P2A_SDOUT1
    ,output  PMOD_P2A_PDN
    ,output  PMOD_P2A_MCLK

    ,inout   PMOD_P2B_I2C_SDA
    ,inout   PMOD_P2B_I2C_SCL
    ,output  PMOD_P2B_LRCK
    ,output  PMOD_P2B_BICK
    ,output  PMOD_P2B_SDIN1
    ,input   PMOD_P2B_SDOUT1
    ,output  PMOD_P2B_PDN
    ,output  PMOD_P2B_MCLK

    ,inout   PMOD_P3A_I2C_SDA
    ,inout   PMOD_P3A_I2C_SCL
    ,output  PMOD_P3A_LRCK
    ,output  PMOD_P3A_BICK
    ,output  PMOD_P3A_SDIN1
    ,input   PMOD_P3A_SDOUT1
    ,output  PMOD_P3A_PDN
    ,output  PMOD_P3A_MCLK

    ,inout   PMOD_P3B_I2C_SDA
    ,inout   PMOD_P3B_I2C_SCL
    ,output  PMOD_P3B_LRCK
    ,output  PMOD_P3B_BICK
    ,output  PMOD_P3B_SDIN1
    ,input   PMOD_P3B_SDOUT1
    ,output  PMOD_P3B_PDN
    ,output  PMOD_P3B_MCLK

    // Button used for reset and output cal. Assumed momentary, pressed == HIGH.
    // You can use any random PMOD that has a button on it.
    ,input   RESET_BUTTON
    // UART used for debug information and for calibration.
    ,output  UART_TX
);

logic rst;
logic clk_12mhz;
logic sample_clk;

// Signals for PMOD_P2A
logic signed [W-1:0] p2a_in0;
logic signed [W-1:0] p2a_in1;
logic signed [W-1:0] p2a_in2;
logic signed [W-1:0] p2a_in3;
logic signed [W-1:0] p2a_out0;
logic signed [W-1:0] p2a_out1;
logic signed [W-1:0] p2a_out2;
logic signed [W-1:0] p2a_out3;
logic [7:0]          p2a_jack;
logic                p2a_i2c_scl_oe;
logic                p2a_i2c_scl_i;
logic                p2a_i2c_sda_oe;
logic                p2a_i2c_sda_i;

// Signals for PMOD_P2B
logic signed [W-1:0] p2b_in0;
logic signed [W-1:0] p2b_in1;
logic signed [W-1:0] p2b_in2;
logic signed [W-1:0] p2b_in3;
logic signed [W-1:0] p2b_out0;
logic signed [W-1:0] p2b_out1;
logic signed [W-1:0] p2b_out2;
logic signed [W-1:0] p2b_out3;
logic [7:0]          p2b_jack;
logic                p2b_i2c_scl_oe;
logic                p2b_i2c_scl_i;
logic                p2b_i2c_sda_oe;
logic                p2b_i2c_sda_i;

// Signals for PMOD_P3A
logic signed [W-1:0] p3a_in0;
logic signed [W-1:0] p3a_in1;
logic signed [W-1:0] p3a_in2;
logic signed [W-1:0] p3a_in3;
logic signed [W-1:0] p3a_out0;
logic signed [W-1:0] p3a_out1;
logic signed [W-1:0] p3a_out2;
logic signed [W-1:0] p3a_out3;
logic [7:0]          p3a_jack;
logic                p3a_i2c_scl_oe;
logic                p3a_i2c_scl_i;
logic                p3a_i2c_sda_oe;
logic                p3a_i2c_sda_i;

// Signals for PMOD_P3B
logic signed [W-1:0] p3b_in0;
logic signed [W-1:0] p3b_in1;
logic signed [W-1:0] p3b_in2;
logic signed [W-1:0] p3b_in3;
logic signed [W-1:0] p3b_out0;
logic signed [W-1:0] p3b_out1;
logic signed [W-1:0] p3b_out2;
logic signed [W-1:0] p3b_out3;
logic [7:0]          p3b_jack;
logic                p3b_i2c_scl_oe;
logic                p3b_i2c_scl_i;
logic                p3b_i2c_sda_oe;
logic                p3b_i2c_sda_i;

// PLL bringup and reset state management / debouncing.
sysmgr sysmgr_instance (
    // The input clock frequency might be different for different boards.
    .clk_in(CLK),
    .rst_in(1'b0),
    .clk_12m(clk_12mhz),
    .rst_out(rst)
);

mirror #(
    .W(W)
) core_p2a (
    .rst         (rst),
    .clk         (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0  (p2a_in0),
    .sample_in1  (p2a_in1),
    .sample_in2  (p2a_in2),
    .sample_in3  (p2a_in3),
    .sample_out0 (p2a_out0),
    .sample_out1 (p2a_out1),
    .sample_out2 (p2a_out2),
    .sample_out3 (p2a_out3),
    .jack        (p2a_jack)
);

mirror #(
    .W(W)
) core_p2b (
    .rst         (rst),
    .clk         (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0  (p2b_in0),
    .sample_in1  (p2b_in1),
    .sample_in2  (p2b_in2),
    .sample_in3  (p2b_in3),
    .sample_out0 (p2b_out0),
    .sample_out1 (p2b_out1),
    .sample_out2 (p2b_out2),
    .sample_out3 (p2b_out3),
    .jack        (p2b_jack)
);

mirror #(
    .W(W)
) core_p3a (
    .rst         (rst),
    .clk         (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0  (p3a_in0),
    .sample_in1  (p3a_in1),
    .sample_in2  (p3a_in2),
    .sample_in3  (p3a_in3),
    .sample_out0 (p3a_out0),
    .sample_out1 (p3a_out1),
    .sample_out2 (p3a_out2),
    .sample_out3 (p3a_out3),
    .jack        (p3a_jack)
);

mirror #(
    .W(W)
) core_p3b (
    .rst         (rst),
    .clk         (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0  (p3b_in0),
    .sample_in1  (p3b_in1),
    .sample_in2  (p3b_in2),
    .sample_in3  (p3b_in3),
    .sample_out0 (p3b_out0),
    .sample_out1 (p3b_out1),
    .sample_out2 (p3b_out2),
    .sample_out3 (p3b_out3),
    .jack        (p3b_jack)
);

eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) pmod_p2a_inst (
    .clk_12mhz(clk_12mhz),
    .rst(rst),
    .sample_clk   (sample_clk),

    .i2c_scl_oe(p2a_i2c_scl_oe),
    .i2c_scl_i (p2a_i2c_scl_i),
    .i2c_sda_oe(p2a_i2c_sda_oe),
    .i2c_sda_i (p2a_i2c_sda_i),
    .pdn    (PMOD_P2A_PDN),
    .mclk   (PMOD_P2A_MCLK),
    .sdin1  (PMOD_P2A_SDIN1),
    .sdout1 (PMOD_P2A_SDOUT1),
    .lrck   (PMOD_P2A_LRCK),
    .bick   (PMOD_P2A_BICK),

    .cal_in0      (p2a_in0),
    .cal_in1      (p2a_in1),
    .cal_in2      (p2a_in2),
    .cal_in3      (p2a_in3),
    .cal_out0     (p2a_out0),
    .cal_out1     (p2a_out1),
    .cal_out2     (p2a_out2),
    .cal_out3     (p2a_out3),
    .jack         (p2a_jack),

    /* Unused debug stuff */
    .eeprom_mfg    (),
    .eeprom_dev    (),
    .eeprom_serial (),
    .sample_adc0   (),
    .sample_adc1   (),
    .sample_adc2   (),
    .sample_adc3   (),
    .force_dac_output(0) // Do not force output.
);

eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) pmod_p2b_inst (
    .clk_12mhz(clk_12mhz),
    .rst(rst),
    .sample_clk   (),

    .i2c_scl_oe(p2b_i2c_scl_oe),
    .i2c_scl_i (p2b_i2c_scl_i),
    .i2c_sda_oe(p2b_i2c_sda_oe),
    .i2c_sda_i (p2b_i2c_sda_i),
    .pdn    (PMOD_P2B_PDN),
    .mclk   (PMOD_P2B_MCLK),
    .sdin1  (PMOD_P2B_SDIN1),
    .sdout1 (PMOD_P2B_SDOUT1),
    .lrck   (PMOD_P2B_LRCK),
    .bick   (PMOD_P2B_BICK),

    .cal_in0      (p2b_in0),
    .cal_in1      (p2b_in1),
    .cal_in2      (p2b_in2),
    .cal_in3      (p2b_in3),
    .cal_out0     (p2b_out0),
    .cal_out1     (p2b_out1),
    .cal_out2     (p2b_out2),
    .cal_out3     (p2b_out3),
    .jack         (p2b_jack),

    /* Unused debug stuff */
    .eeprom_mfg    (),
    .eeprom_dev    (),
    .eeprom_serial (),
    .sample_adc0   (),
    .sample_adc1   (),
    .sample_adc2   (),
    .sample_adc3   (),
    .force_dac_output(0) // Do not force output.
);

eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) pmod_p3a_inst (
    .clk_12mhz(clk_12mhz),
    .rst(rst),
    .sample_clk   (),

    .i2c_scl_oe(p3a_i2c_scl_oe),
    .i2c_scl_i (p3a_i2c_scl_i),
    .i2c_sda_oe(p3a_i2c_sda_oe),
    .i2c_sda_i (p3a_i2c_sda_i),
    .pdn    (PMOD_P3A_PDN),
    .mclk   (PMOD_P3A_MCLK),
    .sdin1  (PMOD_P3A_SDIN1),
    .sdout1 (PMOD_P3A_SDOUT1),
    .lrck   (PMOD_P3A_LRCK),
    .bick   (PMOD_P3A_BICK),

    .cal_in0      (p3a_in0),
    .cal_in1      (p3a_in1),
    .cal_in2      (p3a_in2),
    .cal_in3      (p3a_in3),
    .cal_out0     (p3a_out0),
    .cal_out1     (p3a_out1),
    .cal_out2     (p3a_out2),
    .cal_out3     (p3a_out3),
    .jack         (p3a_jack),

    /* Unused debug stuff */
    .eeprom_mfg    (),
    .eeprom_dev    (),
    .eeprom_serial (),
    .sample_adc0   (),
    .sample_adc1   (),
    .sample_adc2   (),
    .sample_adc3   (),
    .force_dac_output(0) // Do not force output.
);

eurorack_pmod #(
    .W(W),
    .CAL_MEM_FILE("cal/cal_mem.hex")
) pmod_p3b_inst (
    .clk_12mhz(clk_12mhz),
    .rst(rst),
    .sample_clk   (),

    .i2c_scl_oe(p3b_i2c_scl_oe),
    .i2c_scl_i (p3b_i2c_scl_i),
    .i2c_sda_oe(p3b_i2c_sda_oe),
    .i2c_sda_i (p3b_i2c_sda_i),
    .pdn    (PMOD_P3B_PDN),
    .mclk   (PMOD_P3B_MCLK),
    .sdin1  (PMOD_P3B_SDIN1),
    .sdout1 (PMOD_P3B_SDOUT1),
    .lrck   (PMOD_P3B_LRCK),
    .bick   (PMOD_P3B_BICK),

    .cal_in0      (p3b_in0),
    .cal_in1      (p3b_in1),
    .cal_in2      (p3b_in2),
    .cal_in3      (p3b_in3),
    .cal_out0     (p3b_out0),
    .cal_out1     (p3b_out1),
    .cal_out2     (p3b_out2),
    .cal_out3     (p3b_out3),
    .jack         (p3b_jack),

    /* Unused debug stuff */
    .eeprom_mfg    (),
    .eeprom_dev    (),
    .eeprom_serial (),
    .sample_adc0   (),
    .sample_adc1   (),
    .sample_adc2   (),
    .sample_adc3   (),
    .force_dac_output(0) // Do not force output.
);

`ifdef ECP5
`ifndef VERILATOR_LINT_ONLY
// Tristating for PMOD_P2A
TRELLIS_IO #(.DIR("BIDIR")) p2a_i2c_tristate_scl (
    .I(1'b0),
    .T(~p2a_i2c_scl_oe),
    .B(PMOD_P2A_I2C_SCL),
    .O(p2a_i2c_scl_i)
);
TRELLIS_IO #(.DIR("BIDIR")) p2a_i2c_tristate_sda (
    .I(1'b0),
    .T(~p2a_i2c_sda_oe),
    .B(PMOD_P2A_I2C_SDA),
    .O(p2a_i2c_sda_i)
);
// Tristating for PMOD_P2B
TRELLIS_IO #(.DIR("BIDIR")) p2b_i2c_tristate_scl (
    .I(1'b0),
    .T(~p2b_i2c_scl_oe),
    .B(PMOD_P2B_I2C_SCL),
    .O(p2b_i2c_scl_i)
);
TRELLIS_IO #(.DIR("BIDIR")) p2b_i2c_tristate_sda (
    .I(1'b0),
    .T(~p2b_i2c_sda_oe),
    .B(PMOD_P2B_I2C_SDA),
    .O(p2b_i2c_sda_i)
);
// Tristating for PMOD_P3A
TRELLIS_IO #(.DIR("BIDIR")) p3a_i2c_tristate_scl (
    .I(1'b0),
    .T(~p3a_i2c_scl_oe),
    .B(PMOD_P3A_I2C_SCL),
    .O(p3a_i2c_scl_i)
);
TRELLIS_IO #(.DIR("BIDIR")) p3a_i2c_tristate_sda (
    .I(1'b0),
    .T(~p3a_i2c_sda_oe),
    .B(PMOD_P3A_I2C_SDA),
    .O(p3a_i2c_sda_i)
);
// Tristating for PMOD_P3B
TRELLIS_IO #(.DIR("BIDIR")) p3b_i2c_tristate_scl (
    .I(1'b0),
    .T(~p3b_i2c_scl_oe),
    .B(PMOD_P3B_I2C_SCL),
    .O(p3b_i2c_scl_i)
);
TRELLIS_IO #(.DIR("BIDIR")) p3b_i2c_tristate_sda (
    .I(1'b0),
    .T(~p3b_i2c_sda_oe),
    .B(PMOD_P3B_I2C_SDA),
    .O(p3b_i2c_sda_i)
);
`endif
`endif

endmodule
