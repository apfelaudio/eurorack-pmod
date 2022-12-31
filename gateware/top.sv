// Top-level module for using `eurorack-pmod` with Icebreaker FPGA.
//
// The defines below allow you to select calibration mode, spit samples out
// UART, or select one of the user-defined 'cores' (DSP modules).

// Transmit CODEC samples over UART
`define UART_SAMPLE_TRANSMITTER

// Transmit raw CODEC samples, bypassing the input
// calibration logic (necessary for calibrating inputs).
//`define UART_SAMPLE_TRANSMIT_RAW_ADC

// Force the output DAC to a specific value depending on
// the position of the uButton (necessary for output cal).
//`define OUTPUT_CALIBRATION

//`define CORE_CLKDIV
`define CORE_SEQSWITCH
//`define CORE_SAMPLER
//`define CORE_MIRROR
//`define CORE_VCA
//`define CORE_VCO
//`define CORE_FILTER
//`define CORE_BITCRUSH

module top (
     input   CLK
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

localparam clk_freq = 12_000_000;
localparam baud = 115200;

wire sample_clk;

// Raw samples to/from CODEC
wire signed [15:0] sample_adc0;
wire signed [15:0] sample_adc1;
wire signed [15:0] sample_adc2;
wire signed [15:0] sample_adc3;
wire signed [15:0] sample_dac0;
wire signed [15:0] sample_dac1;
wire signed [15:0] sample_dac2;
wire signed [15:0] sample_dac3;

// Calibrated samples to/from CODEC
wire signed [15:0] cal_in0;
wire signed [15:0] cal_in1;
wire signed [15:0] cal_in2;
wire signed [15:0] cal_in3;
wire signed [15:0] cal_out0;
wire signed [15:0] cal_out1;
wire signed [15:0] cal_out2;
wire signed [15:0] cal_out3;

input_cal input_cal_instance (
    .clk     (CLK),
    .sample_clk  (sample_clk),
    // Note: inputs samples are inverted by analog frontend
    // Should add +1 for precise 2s complement sign change
    .adc_in0 (~sample_adc0),
    .adc_in1 (~sample_adc1),
    .adc_in2 (~sample_adc2),
    .adc_in3 (~sample_adc3),
    .cal_in0 (cal_in0),
    .cal_in1 (cal_in1),
    .cal_in2 (cal_in2),
    .cal_in3 (cal_in3)
);

`ifdef CORE_MIRROR
assign cal_out0 = cal_in0;
assign cal_out1 = cal_in1;
assign cal_out2 = cal_in2;
assign cal_out3 = cal_in3;
`endif

`ifdef CORE_SAMPLER
sampler sampler_instance (
    .clk     (CLK),
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
    .clk     (CLK),
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
    .clk     (CLK),
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
    .clk     (CLK),
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
    .clk     (CLK),
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
    .clk     (CLK),
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
    .clk     (CLK),
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

`ifdef OUTPUT_CALIBRATION

wire signed [15:0] force_cal_output = BTN_N ? 20000 : -20000;
assign sample_dac0 = force_cal_output;
assign sample_dac1 = force_cal_output;
assign sample_dac2 = force_cal_output;
assign sample_dac3 = force_cal_output;

`else

output_cal output_cal_instance (
    .clk        (CLK),
    .sample_clk (sample_clk),
    .cal_out0   (cal_out0),
    .cal_out1   (cal_out1),
    .cal_out2   (cal_out2),
    .cal_out3   (cal_out3),
    .dac_out0   (sample_dac0),
    .dac_out1   (sample_dac1),
    .dac_out2   (sample_dac2),
    .dac_out3   (sample_dac3)
);

`endif

ak4619 ak4619_instance (
    .clk     (CLK),
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

reg tx1_start;
reg [7:0] tx1_data;
reg tx1_busy;
reg led1_toggle = 1'b0;
reg led2_toggle = 1'b0;
assign LEDR_N = led1_toggle;
assign LEDG_N = led2_toggle;

uart_tx #(clk_freq, baud) utx1 (
	.clk(CLK),
	.tx_start(tx1_start),
	.tx_data(tx1_data),
	.tx(TX),
	.tx_busy(tx1_busy)
);

localparam
	SENT0      = 4'h0,
	SENT1      = 4'h1,
    CH_ID      = 4'h2,
	MSB        = 4'h3,
	LSB        = 4'h4;

reg [3:0] state = SENT0;
reg [1:0] cur_ch = 0;
reg last_sample_clk = 0;

reg signed [15:0] adc_word_out = 16'h0;

always @(posedge CLK) begin
    if (sample_clk && ~last_sample_clk && state == CH_ID) begin
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
        led1_toggle <= ~led1_toggle;
    end
    last_sample_clk <= sample_clk;
    if(~tx1_busy) begin
        case (state)
            SENT0: tx1_data <= "C";
            SENT1: tx1_data <= "H";
            CH_ID: tx1_data <= "0" + cur_ch;
            MSB:  tx1_data <= (adc_word_out & 16'hFF00) >> 8;
            LSB:  tx1_data <= (adc_word_out & 16'h00FF);
        endcase

        tx1_start <= 1'b1;

        if(state < LSB) begin
            state <= state + 1;
        end else begin
            state <= SENT0;
            cur_ch <= cur_ch + 1;
            led2_toggle <= ~led2_toggle;
        end
    end
end

`endif

endmodule
