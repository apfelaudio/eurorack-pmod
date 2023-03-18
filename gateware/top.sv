// Top-level module for using `eurorack-pmod` with Icebreaker FPGA.
//
// The defines below allow you to select calibration mode, spit samples out
// UART, or select one of the user-defined 'cores' (DSP modules).

`default_nettype none

// Transmit CODEC samples over UART
`define UART_SAMPLE_TRANSMITTER

// Transmit raw CODEC samples, bypassing the input
// calibration logic (necessary for calibrating inputs).
`define UART_SAMPLE_TRANSMIT_RAW_ADC

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

`define CORE_MIRROR
//`define CORE_CLKDIV
//`define CORE_SEQSWITCH
//`define CORE_SAMPLER
//`define CORE_VCA
//`define CORE_VCO
//`define CORE_FILTER
//`define CORE_BITCRUSH
//`define CORE_DELAY_RAW
//`define CORE_PITCH_SHIFT
//`define CORE_ECHO

module top #(
    parameter int W = 16 // sample width, bits
)(
     input   CLK // Assumed 12Mhz
    ,output  P2_1
    ,inout   P2_2
    ,output  P2_3
    ,output  P2_4
    ,output  P2_7
    ,input   P2_8
    ,output  P2_9
    ,output  P2_10
`ifdef UART_SAMPLE_TRANSMITTER
    // UART and LEDs for samples being transmitted.
    ,output TX
    ,output LEDR_N
    ,output LEDG_N
`endif
    ,input   BTN_N
);

logic rst;
logic clk_12mhz;
logic clk_24mhz;
logic sample_clk;

ice40_sysmgr ice40_sysmgr_instance (
    .clk_in(CLK),
`ifdef OUTPUT_CALIBRATION
    // For output calibration the button is used elsewhere.
    .rst_in(1'b1),
`else
    .rst_in(~BTN_N),
`endif
    .clk_2x_out(clk_24mhz),
    .clk_1x_out(clk_12mhz),
    .rst_out(rst)
);

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

`ifdef OUTPUT_CALIBRATION

logic signed [W-1:0] force_cal_output;
assign force_cal_output = BTN_N ? 20000 : -20000;
assign sample_dac0 = force_cal_output;
assign sample_dac1 = force_cal_output;
assign sample_dac2 = force_cal_output;
assign sample_dac3 = force_cal_output;

`endif

cal cal_instance (
    .clk (clk_12mhz),
    .sample_clk (sample_clk),
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
`ifdef OUTPUT_CALIBRATION
    // In output calibration mode this is driven from elsewhere.
    .out4 (),
    .out5 (),
    .out6 (),
    .out7 ()
`else
    .out4 (sample_dac0),
    .out5 (sample_dac1),
    .out6 (sample_dac2),
    .out7 (sample_dac3)
`endif
);

`ifdef CORE_MIRROR
assign cal_out0 = cal_in0;
assign cal_out1 = cal_in1;
assign cal_out2 = cal_in2;
assign cal_out3 = cal_in3;
`endif

`ifdef CORE_SAMPLER
sampler sampler_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_CLKDIV
clkdiv clkdiv_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_SEQSWITCH
seqswitch seqswitch_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_BITCRUSH
bitcrush bitcrush_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_VCA
vca vca_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_FILTER
filter filter_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_VCO
vco vco_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_DELAY_RAW
delay_raw delay_raw_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_PITCH_SHIFT
pitch_shift pitch_shift_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

`ifdef CORE_ECHO
stereo_echo echo_instance (
    .clk     (clk_12mhz),
    .sample_clk  (sample_clk),
    .sample_in0 (cal_in0),
    .sample_in1 (cal_in1),
    .sample_in2 (cal_in2),
    .sample_in3 (cal_in3),
    .sample_out0 (cal_out0),
    .sample_out1 (cal_out1),
    .sample_out2 (cal_out2),
    .sample_out3 (cal_out3)
);
`endif

ak4619 ak4619_instance (
    .clk     (clk_12mhz),
    .rst     (rst),
    .pdn     (),
    .mclk    (P2_4),
    .bick    (P2_10),
    .lrck    (P2_9),
    .sdin1   (P2_7),
    .sdout1  (P2_8),
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
assign P2_1 = i2c_scl_oe ? 1'b0 : 1'bz;
assign P2_2 = i2c_sda_oe ? 1'b0 : 1'bz;
assign P2_3 = 1'b0;

logic [7:0] jack;

pmod_i2c_master pmod_i2c_master_instance (
    .clk(clk_12mhz),
    .rst(rst),

    .scl_oe(i2c_scl_oe),
    .scl_i(P2_1),
    .sda_oe(i2c_sda_oe),
    .sda_i(P2_2),

    .led0( jack ),
    .led1( cal_in1[W-1:W-8]),
    .led2( cal_in2[W-1:W-8]),
    .led3( cal_in3[W-1:W-8]),
    .led4(cal_out0[W-1:W-8]),
    .led5(cal_out1[W-1:W-8]),
    .led6(cal_out2[W-1:W-8]),
    .led7(cal_out3[W-1:W-8]),

    .jack(jack),

    .eeprom_mfg_code(),
    .eeprom_dev_code(),
    .eeprom_serial()
);

`ifdef UART_SAMPLE_TRANSMITTER

cal_uart cal_uart_instance (
    .clk (clk_12mhz),
    .tx_o(TX),
`ifdef UART_SAMPLE_TRANSMIT_RAW_ADC
     // Used for calibrating the input channels
    .in0(sample_adc0),
    .in1(sample_adc1),
    .in2(sample_adc2),
    .in3(sample_adc3)
`else
    .in0(cal_in0),
    .in1(cal_in1),
    .in2(cal_in2),
    .in3(cal_in3)
`endif
);

`endif

endmodule
