// Helper module to emit debug information out a UART for calibration purposes.
//
// This is not part of 'normal' projects, it's only used for board bringup.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`, which depends on this module.

`default_nettype none

module debug_uart #(
    parameter W = 16, // sample width
    parameter WM = 32, // maximum sample width
    parameter DIV = 12 // baud rate == CLK / DIV
)(
    input clk,
    input rst,
    output tx_o,
    input [7:0] eeprom_mfg,
    input [7:0] eeprom_dev,
    input [31:0] eeprom_serial,
    input [7:0] jack,
    input [7:0] touch0,
    input [7:0] touch1,
    input [7:0] touch2,
    input [7:0] touch3,
    input [7:0] touch4,
    input [7:0] touch5,
    input [7:0] touch6,
    input [7:0] touch7,
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

logic signed [WM-1:0] adc0_ex;
logic signed [WM-1:0] adc1_ex;
logic signed [WM-1:0] adc2_ex;
logic signed [WM-1:0] adc3_ex;

assign adc0_ex = WM'(adc0);
assign adc1_ex = WM'(adc1);
assign adc2_ex = WM'(adc2);
assign adc3_ex = WM'(adc3);

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
            0:   dout <= MAGIC1;
            1:   dout <= MAGIC2;
            2:   dout <= eeprom_mfg;
            3:   dout <= eeprom_dev;
            4:   dout <= eeprom_serial[32    -1:32-1*8];
            5:   dout <= eeprom_serial[32-1*8-1:32-2*8];
            6:   dout <= eeprom_serial[32-2*8-1:32-3*8];
            7:   dout <= eeprom_serial[32-3*8-1:     0];
            8:   dout <= jack;
            9:   dout <= touch0;
            10:  dout <= touch1;
            11:  dout <= touch2;
            12:  dout <= touch3;
            13:  dout <= touch4;
            14:  dout <= touch5;
            15:  dout <= touch6;
            16:  dout <= touch7;
            // Channel 0
            17:   dout <= adc0_ex[WM    -1:WM-1*8];
            18:  dout <= adc0_ex[WM-1*8-1:WM-2*8];
            19:  dout <= adc0_ex[WM-2*8-1:WM-3*8];
            20:  dout <= adc0_ex[WM-3*8-1:     0];
            // Channel 1
            21:  dout <= adc1_ex[WM    -1:WM-1*8];
            22:  dout <= adc1_ex[WM-1*8-1:WM-2*8];
            23:  dout <= adc1_ex[WM-2*8-1:WM-3*8];
            24:  dout <= adc1_ex[WM-3*8-1:     0];
            // Channel 2
            25:  dout <= adc2_ex[WM    -1:WM-1*8];
            26:  dout <= adc2_ex[WM-1*8-1:WM-2*8];
            27:  dout <= adc2_ex[WM-2*8-1:WM-3*8];
            28:  dout <= adc2_ex[WM-3*8-1:     0];
            // Channel 3
            29:  dout <= adc3_ex[WM    -1:WM-1*8];
            30:  dout <= adc3_ex[WM-1*8-1:WM-2*8];
            31:  dout <= adc3_ex[WM-2*8-1:WM-3*8];
            32:  dout <= adc3_ex[WM-3*8-1:     0];
            default: begin
                // Should never get here
            end
        endcase
        if (state != 32) state <= state + 1;
        else state <= 0;
    end
end


endmodule
