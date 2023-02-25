// Helper module to emit samples out a UART for calibration purposes.
//
// This is not part of 'normal' projects, it's only used for board bringup.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`, which depends on this module.

`default_nettype none

module cal_uart #(
    parameter W = 16, // sample width
    parameter DIV = 12 // baud rate == CLK / DIV
)(
    input clk, // 12Mhz
    output tx_o,
    input signed [W-1:0] in0,
    input signed [W-1:0] in1,
    input signed [W-1:0] in2,
    input signed [W-1:0] in3
);

localparam XMIT_ST_SENT0      = 4'h0,
           XMIT_ST_SENT1      = 4'h1,
           XMIT_ST_CH_ID      = 4'h2,
           XMIT_ST_MSB        = 4'h3,
           XMIT_ST_LSB        = 4'h4;

logic tx1_valid = 1;
logic [7:0] tx1_data = 0;
logic tx1_ack;
logic [3:0] state = XMIT_ST_SENT0;
logic [1:0] cur_ch = 0;
logic signed [W-1:0] sample_out = 0;
logic uart_reset = 1;

uart_tx utx (
    .tx(tx_o),
    .data(tx1_data),
    .valid(tx1_valid),
    .ack(tx1_ack),
    .div(DIV-2),
	.clk(clk),
    .rst(uart_reset)
);

always_ff @(posedge clk) begin
    uart_reset <= 0;
    if(tx1_ack) begin
        tx1_valid <= 1'b1;
        case (state)
            XMIT_ST_SENT0: begin
                tx1_data <= "C";
                state <= XMIT_ST_SENT1;
                case (cur_ch)
                    2'h0: sample_out <= in0;
                    2'h1: sample_out <= in1;
                    2'h2: sample_out <= in2;
                    2'h3: sample_out <= in3;
                endcase
            end
            XMIT_ST_SENT1: begin
                tx1_data <= "H";
                state <= XMIT_ST_CH_ID;
            end
            XMIT_ST_CH_ID: begin
                tx1_data <= "0" + 8'(cur_ch);
                state <= XMIT_ST_MSB;
            end
            // Note: we're currently only sending 2 bytes per
            // sample for calibration purposes. This should
            // eventually be derived from the sample width.
            XMIT_ST_MSB: begin
                tx1_data <= 8'((sample_out & 16'hFF00) >> 8);
                state <= XMIT_ST_LSB;
            end
            XMIT_ST_LSB: begin
                tx1_data <= 8'((sample_out & 16'h00FF));
                state <= XMIT_ST_SENT0;
                cur_ch <= cur_ch + 1;
            end
            default: begin
                // Should never reach here
            end
        endcase
    end
end


endmodule
