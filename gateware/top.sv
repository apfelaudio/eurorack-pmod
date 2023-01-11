// Top-level module for using `eurorack-pmod` with Icebreaker FPGA.
//
// The defines below allow you to select calibration mode, spit samples out
// UART, or select one of the user-defined 'cores' (DSP modules).

`default_nettype none

// Transmit CODEC samples over UART
`define UART_SAMPLE_TRANSMITTER

// Transmit raw CODEC samples, bypassing the input
// calibration logic (necessary for calibrating inputs).
//`define UART_SAMPLE_TRANSMIT_RAW_ADC

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

//`define CORE_CLKDIV
//`define CORE_SEQSWITCH
//`define CORE_SAMPLER
`define CORE_MIRROR
//`define CORE_VCA
//`define CORE_VCO
//`define CORE_FILTER
//`define CORE_BITCRUSH

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
`ifdef OUTPUT_CALIBRATION
    // Button to toggle between +/- 5V output cal.
    ,input   BTN_N
`endif
);

// 12MHz master clock == 12MHz / 128 == 93.75KHz sample clock.
// For a 'true' 96KHz sample clock we probably want a 12.288MHz
// crystal, as the PLL can't actually achieve it alone.

localparam CLK_FREQ  = 12_000_000;
localparam BAUD_RATE =    115_200;

logic clk_12mhz;
logic sample_clk;
assign clk_12mhz = CLK;

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
`ifndef OUTPUT_CALIBRATION
    // In output calibration mode these wires are forced.
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

ak4619 ak4619_instance (
    .clk     (clk_12mhz),
    .pdn     (P2_3),
    .mclk    (P2_4),
    .bick    (P2_10),
    .lrck    (P2_9),
    .sdin1   (P2_7),
    .sdout1  (P2_8),
    .i2c_scl (P2_1),
    .i2c_sda (P2_2),
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


`ifdef UART_SAMPLE_TRANSMITTER

localparam int XMIT_ST_SENT0      = 4'h0,
               XMIT_ST_SENT1      = 4'h1,
               XMIT_ST_CH_ID      = 4'h2,
               XMIT_ST_MSB        = 4'h3,
               XMIT_ST_LSB        = 4'h4;

logic tx1_start;
logic [7:0] tx1_data;
logic tx1_busy;
logic led1_toggle = 1'b0;
logic led2_toggle = 1'b0;
logic [3:0] state = XMIT_ST_SENT0;
logic [1:0] cur_ch = 0;
logic signed [W-1:0] adc_word_out = 16'h0;

assign LEDR_N = led1_toggle;
assign LEDG_N = led2_toggle;

uart_tx #(CLK_FREQ, BAUD_RATE) utx1 (
	.clk(clk_12mhz),
	.tx_start(tx1_start),
	.tx_data(tx1_data),
	.tx(TX),
	.tx_busy(tx1_busy)
);

always_ff @(posedge clk_12mhz) begin
    led1_toggle <= ~led1_toggle;
    if(~tx1_busy) begin
        tx1_start <= 1'b1;
        case (state)
            XMIT_ST_SENT0: begin
                tx1_data <= "C";
                state <= XMIT_ST_SENT1;
                case (cur_ch)
                    `ifdef UART_SAMPLE_TRANSMIT_RAW_ADC
                    // Used for calibrating the input channels
                    2'h0: adc_word_out <= sample_adc0;
                    2'h1: adc_word_out <= sample_adc1;
                    2'h2: adc_word_out <= sample_adc2;
                    2'h3: adc_word_out <= sample_adc3;
                    `else
                    2'h0: adc_word_out <= cal_in0;
                    2'h1: adc_word_out <= cal_in1;
                    2'h2: adc_word_out <= cal_in2;
                    2'h3: adc_word_out <= cal_in3;
                    `endif
                endcase
            end
            XMIT_ST_SENT1: begin
                tx1_data <= "H";
                state <= XMIT_ST_CH_ID;
            end
            XMIT_ST_CH_ID: begin
                tx1_data <= "0" + cur_ch;
                state <= XMIT_ST_MSB;
            end
            XMIT_ST_MSB: begin
                tx1_data <= (adc_word_out & 16'hFF00) >> 8;
                state <= XMIT_ST_LSB;
            end
            XMIT_ST_LSB: begin
                tx1_data <= (adc_word_out & 16'h00FF);
                state <= XMIT_ST_SENT0;
                cur_ch <= cur_ch + 1;
                led2_toggle <= ~led2_toggle;
            end
        endcase
    end
end

`endif

endmodule
