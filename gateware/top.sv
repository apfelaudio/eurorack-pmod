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
//`define CORE_LED_TEST

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

    // Flipped here and in instantiation, ribbon cable.
    ,output  P1A7
    ,inout   P1A8
    ,output  P1A9
    ,output  P1A10
    ,output  P1A1
    ,input   P1A2
    ,output  P1A3
    ,output  P1A4

    // Flipped here and in instantiation, ribbon cable.
    ,output  P1B7
    ,inout   P1B8
    ,output  P1B9
    ,output  P1B10
    ,output  P1B1
    ,input   P1B2
    ,output  P1B3
    ,output  P1B4

    // Not flipped
    ,output  P2_1
    ,inout   P2_2
    ,output  P2_3
    ,output  P2_4
    ,output  P2_7
    ,input   P2_8
    ,output  P2_9
    ,output  P2_10

    ,input   BTN_N
);

logic rst;
logic clk_12mhz;
logic clk_24mhz;

ice40_sysmgr ice40_sysmgr_instance (
    .clk_in(CLK),
`ifdef OUTPUT_CALIBRATION
    // For output calibration the button is used elsewhere.
    .rst_in(1'b0),
`else
    .rst_in(~BTN_N),
`endif
    .clk_2x_out(clk_24mhz),
    .clk_1x_out(clk_12mhz),
    .rst_out(rst)
);

pmod1 pmod_instance1 (
    .rst(rst),
    .clk_12mhz(clk_12mhz),
    .i2c_scl(P1A7),
    .i2c_sda(P1A8),
    .pdn    (P1A9),
    .mclk   (P1A10),
    .sdin1  (P1A1),
    .sdout1 (P1A2),
    .lrck   (P1A3),
    .bick   (P1A4)
);

pmod2 pmod_instance2 (
    .rst(rst),
    .clk_12mhz(clk_12mhz),
    .i2c_scl(P1B7),
    .i2c_sda(P1B8),
    .pdn    (P1B9),
    .mclk   (P1B10),
    .sdin1  (P1B1),
    .sdout1 (P1B2),
    .lrck   (P1B3),
    .bick   (P1B4)
);

/*
pmod pmod_instance3 (
    .rst(rst),
    .clk_12mhz(clk_12mhz),
    .i2c_scl(P2_1),
    .i2c_sda(P2_2),
    .pdn    (P2_3),
    .mclk   (P2_4),
    .sdin1  (P2_7),
    .sdout1 (P2_8),
    .lrck   (P2_9),
    .bick   (P2_10)
);
*/

endmodule
