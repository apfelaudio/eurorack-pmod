module top (
    input   CLK,
    output  P2_1,
    inout   P2_2,
    output  P2_3,
    output  P2_4,
    output  P2_7,
    input   P2_8,
    output  P2_9,
    output  P2_10,
  	output TX,
    output LEDR_N,
    output LEDG_N
);

localparam clk_freq = 12_000_000;
localparam baud = 115200;

wire sample_clk;
wire [15:0] sample_out0;
wire [15:0] sample_out1;
wire [15:0] sample_out2;
wire [15:0] sample_out3;
wire [15:0] sample_in0;
wire [15:0] sample_in1;
wire [15:0] sample_in2;
wire [15:0] sample_in3;

sample sample_instance (
    .sample_clk  (sample_clk),
    // Note: inputs samples are inverted by analog frontend
    // Should add +1 for precise 2s complement sign change
    .sample_in0 (~sample_out0),
    .sample_in1 (~sample_out1),
    .sample_in2 (~sample_out2),
    .sample_in3 (~sample_out3),
    .sample_out0 (sample_in0),
    .sample_out1 (sample_in1),
    .sample_out2 (sample_in2),
    .sample_out3 (sample_in3)
);

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
    .sample_out0 (sample_out0),
    .sample_out1 (sample_out1),
    .sample_out2 (sample_out2),
    .sample_out3 (sample_out3),
    .sample_in0 (sample_in0),
    .sample_in1 (sample_in1),
    .sample_in2 (sample_in2),
    .sample_in3 (sample_in3)
);

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
            2'h0: adc_word_out <= sample_in0;
            2'h1: adc_word_out <= sample_in1;
            2'h2: adc_word_out <= sample_in2;
            2'h3: adc_word_out <= sample_in3;
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

endmodule
