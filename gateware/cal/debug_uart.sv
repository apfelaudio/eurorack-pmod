// Helper module to emit debug information out a UART for calibration purposes.
//
// This is not part of 'normal' projects, it's only used for board bringup.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`, which depends on this module.

`default_nettype none

module debug_uart #(
    parameter W = 16, // sample width
    parameter DIV = 12 // baud rate == CLK / DIV
)(
    input clk, // 12Mhz
    input rst,
    output tx_o,
    input [7:0] eeprom_mfg,
    input [7:0] eeprom_dev,
    input [31:0] eeprom_serial,
    input [7:0] jack,
    input signed [W-1:0] adc0,
    input signed [W-1:0] adc1,
    input signed [W-1:0] adc2,
    input signed [W-1:0] adc3
);

localparam MAGIC1 = 8'hBE,
           MAGIC2 = 8'hEF;

logic tx1_valid;
logic [7:0] dout;
logic tx1_ack;
logic [7:0] state;

uart_tx utx (
    .tx(tx_o),
    .data(dout),
    .valid(tx1_valid),
    .ack(tx1_ack),
    .div(DIV-2),
	.clk(clk),
    .rst(rst)
);

always_ff @(posedge clk) begin
    if (rst) begin
        state <= 0;
        tx1_valid <= 1;
        dout <= 0;
    end else if(tx1_ack) begin
        tx1_valid <= 1'b1;
        case (state)
            0:  dout <= MAGIC1;
            1:  dout <= MAGIC2;
            2:  dout <= eeprom_mfg;
            3:  dout <= eeprom_dev;
            4:  dout <= eeprom_serial[31      :32-1*8];
            5:  dout <= eeprom_serial[32-1*8-1:32-2*8];
            6:  dout <= eeprom_serial[32-2*8-1:32-3*8];
            7:  dout <= eeprom_serial[32-3*8-1:     0];
            8:  dout <= jack;
            // Note: we're currently only sending 2 bytes per
            // sample for calibration purposes. This should
            // eventually be derived from the sample width.
            9:  dout <= 8'((adc0 & 16'hFF00) >> 8);
            10: dout <= 8'((adc0 & 16'h00FF));
            11: dout <= 8'((adc1 & 16'hFF00) >> 8);
            12: dout <= 8'((adc1 & 16'h00FF));
            13: dout <= 8'((adc2 & 16'hFF00) >> 8);
            14: dout <= 8'((adc2 & 16'h00FF));
            15: dout <= 8'((adc3 & 16'hFF00) >> 8);
            16: dout <= 8'((adc3 & 16'h00FF));
            default: begin
                // Should never get here
            end
        endcase
        if (state != 24) state <= state + 1;
        else state <= 0;
    end
end


endmodule
