// Driver for I2C traffic to/from the `eurorack-pmod`.
//
// For HW Rev. 3+, this is:
//    - AK4619 Audio Codec (I2C for configuration only, data is I2S)
//    - 24AA025UIDT I2C EEPROM with unique ID
//    - PCA9635 I2C PWM LED controller
//    - PCA9557 I2C GPIO expander (for jack detection)
//
// This kind of stateful stuff is often best suited for a softcore rather
// than pure Verilog, however I wanted to make it possible to use all
// functions of the board without having to resort to using a softcore.

`default_nettype none

module pmod_i2c_master #(
    parameter CODEC_CFG  = "drivers/ak4619-cfg.hex",
    parameter CODEC_CFG_BYTES = 16'd23,
    parameter LED_CFG  = "drivers/pca9635-cfg.hex",
    parameter LED_CFG_BYTES = 16'd26
)(
    input  clk,
    input  rst,

    // I2C signals to be routed to PMOD IO.
	output scl_oe,
	input  scl_i,
	output sda_oe,
	input  sda_i,

    // Signed LED values, -128 (max red) to 127 (max green).
    // The hardware actually allows lighting both LEDs simultaneously,
    // but for now this interface is good enough for visualizing
    // the analog input and output channels.
    input signed [7:0] led0,
    input signed [7:0] led1,
    input signed [7:0] led2,
    input signed [7:0] led3,
    input signed [7:0] led4,
    input signed [7:0] led5,
    input signed [7:0] led6,
    input signed [7:0] led7,

    // Jack detection outputs, 1 == inserted. (bit 0 is input 0, bit 4 is output 0).
    output logic [7:0] jack,

    // Data read from EEPROM after reset.
    output logic [7:0]  eeprom_mfg_code,
    output logic [7:0]  eeprom_dev_code,
    output logic [31:0] eeprom_serial
);

// Overall state machine of this core.
// Basically we bring up the EEPROM and CODEC, and then proceed to
// update the LED outputs and read the jack insertion GPIOS in a loop.
localparam I2C_DELAY1        = 0,
           I2C_EEPROM1       = 1,
           I2C_EEPROM2       = 2,
           I2C_INIT_CODEC1   = 3,
           I2C_INIT_CODEC2   = 4,
           I2C_LED1          = 5, // <<--\ LED/JACK re-runs indefinitely.
           I2C_LED2          = 6, //     |
           I2C_JACK1         = 7, //     |
           I2C_JACK2         = 8, // >>--/
           I2C_IDLE          = 9;

`ifdef COCOTB_SIM
localparam STARTUP_DELAY_BIT = 4;
`else
localparam STARTUP_DELAY_BIT = 17;
`endif

logic [3:0] i2c_state = I2C_DELAY1;

// Index into i2c config memories
logic [15:0] i2c_config_pos = 0;

// Logic for startup configuration of CODEC over I2C.
logic [7:0] codec_config [0:CODEC_CFG_BYTES-1];
initial $readmemh(CODEC_CFG, codec_config);

// Logic for startup configuration of LEDs over I2C.
logic [7:0] led_config [0:LED_CFG_BYTES-1];
initial $readmemh(LED_CFG, led_config);
// Index at which PWM values start in the led config.
localparam PCA9635_PWM0 = 4;

// Valid commands for `i2c_master` core.
localparam [1:0] I2CMASTER_START = 2'b00,
                 I2CMASTER_STOP  = 2'b01,
                 I2CMASTER_WRITE = 2'b10,
                 I2CMASTER_READ  = 2'b11;

// Outbound signals to `i2c_master` core.
logic [7:0] data_in;
logic       ack_in;
logic [1:0] cmd;
logic       stb = 1'b0;

// Inbound signals from `i2c_master` core.
logic [7:0] data_out;
logic       ack_out;
logic       err_out;
logic       ready;

// Used for startup delay.
logic [23:0] delay_cnt;

always_ff @(posedge clk) begin
    if (rst) begin
        i2c_state <= I2C_DELAY1;
        delay_cnt <= 0;
    end else begin
        delay_cnt <= delay_cnt + 1;
        if (ready && ~stb) begin
            case (i2c_state)
                I2C_DELAY1: begin
                    if(delay_cnt[STARTUP_DELAY_BIT])
                        i2c_state <= I2C_EEPROM1;
                end
                I2C_EEPROM1: begin
                    i2c_state <= I2C_EEPROM2;
                    i2c_config_pos <= 0;
                end
                I2C_EEPROM2: begin
                    case (i2c_config_pos)
                        0: cmd <= I2CMASTER_START;
                        // Start a sequential random read transaction.
                        // 0xA0 (command) | 0x2 << 1 (address) | 0 (write)
                        1: begin
                            data_in <= 8'hA4;
                            cmd <= I2CMASTER_WRITE;
                            ack_in <= 1'b1;
                        end
                        // Write address of first word to read == 0xFA.
                        2: data_in <= 8'hFA;
                        3: cmd <= I2CMASTER_START;
                        // Reissue the same command with LSB == 1 (read)
                        4: begin
                            data_in <= 8'hA5;
                            cmd <= I2CMASTER_WRITE;
                        end
                        5: begin
                            cmd <= I2CMASTER_READ;
                            ack_in <= 1'b0;
                        end
                        // Now every byte we read is sequential starting 0xFA.
                        // For now, we only care about unique bytes populated at factory.
                        6:  eeprom_mfg_code <= data_out;
                        7:  eeprom_dev_code <= data_out;
                        8:  eeprom_serial[32-0*8-1:32-1*8] <= data_out;
                        9:  eeprom_serial[32-1*8-1:32-2*8] <= data_out;
                        10: begin
                            eeprom_serial[32-2*8-1:32-3*8] <= data_out;
                            // Do not ack last byte.
                            ack_in <= 1'b1;
                        end
                        11: begin
                            eeprom_serial[32-3*8-1:32-4*8] <= data_out;
                            cmd <= I2CMASTER_STOP;
                            i2c_state <= I2C_INIT_CODEC1;
                            delay_cnt <= 0;
                        end
                        default: begin
                        end
                    endcase
                    i2c_config_pos <= i2c_config_pos + 1;
                    stb <= 1'b1;
                end
                I2C_INIT_CODEC1: begin
                    cmd <= I2CMASTER_START;
                    stb <= 1'b1;
                    i2c_state <= I2C_INIT_CODEC2;
                    i2c_config_pos <= 0;
                end
                I2C_INIT_CODEC2: begin
                    // Shift out all bytes in the CODEC configuration in
                    // one long transaction until we are finished.
                    if (i2c_config_pos != CODEC_CFG_BYTES) begin
                        data_in <= codec_config[5'(i2c_config_pos)];
                        cmd <= I2CMASTER_WRITE;
                        i2c_config_pos <= i2c_config_pos + 1;
                    end else begin
                        cmd <= I2CMASTER_STOP;
                        i2c_state <= I2C_LED1;
                    end
                    ack_in <= 1'b1;
                    stb <= 1'b1;
                end
                I2C_LED1: begin
                    cmd <= I2CMASTER_START;
                    stb <= 1'b1;
                    i2c_state <= I2C_LED2;
                    i2c_config_pos <= 0;
                end
                I2C_LED2: begin
                    case (i2c_config_pos)
                        LED_CFG_BYTES: begin
                            cmd <= I2CMASTER_STOP;
                            i2c_state <= I2C_JACK1;
                        end
                        default: begin
                            data_in <= led_config[5'(i2c_config_pos)];
                            cmd <= I2CMASTER_WRITE;
                        end
                        // Override PWM values from led configuration.
                        PCA9635_PWM0 +  0: data_in <= led0 > 0 ? 0 : -led0;
                        PCA9635_PWM0 +  1: data_in <= led0 > 0 ? led0 : 0;
                        PCA9635_PWM0 +  2: data_in <= led1 > 0 ? 0 : -led1;
                        PCA9635_PWM0 +  3: data_in <= led1 > 0 ? led1 : 0;
                        PCA9635_PWM0 +  4: data_in <= led2 > 0 ? 0 : -led2;
                        PCA9635_PWM0 +  5: data_in <= led2 > 0 ? led2 : 0;
                        PCA9635_PWM0 +  6: data_in <= led3 > 0 ? 0 : -led3;
                        PCA9635_PWM0 +  7: data_in <= led3 > 0 ? led3 : 0;
                        PCA9635_PWM0 +  8: data_in <= led4 > 0 ? 0 : -led4;
                        PCA9635_PWM0 +  9: data_in <= led4 > 0 ? led4 : 0;
                        PCA9635_PWM0 + 10: data_in <= led5 > 0 ? 0 : -led5;
                        PCA9635_PWM0 + 11: data_in <= led5 > 0 ? led5 : 0;
                        PCA9635_PWM0 + 12: data_in <= led6 > 0 ? 0 : -led6;
                        PCA9635_PWM0 + 13: data_in <= led6 > 0 ? led6 : 0;
                        PCA9635_PWM0 + 14: data_in <= led7 > 0 ? 0 : -led7;
                        PCA9635_PWM0 + 15: data_in <= led7 > 0 ? led7 : 0;
                    endcase
                    i2c_config_pos <= i2c_config_pos + 1;
                    ack_in <= 1'b1;
                    stb <= 1'b1;
                end
                I2C_JACK1: begin
                    i2c_state <= I2C_JACK2;
                    i2c_config_pos <= 0;
                end
                I2C_JACK2: begin
                    case (i2c_config_pos)
                        // 1) Configure polarity inversion register.
                        0: cmd <= I2CMASTER_START;
                        1: begin
                            // (0x18 [address] << 1) | 0 [write]
                            data_in <= 8'h30;
                            cmd <= I2CMASTER_WRITE;
                        end
                        2: data_in <= 8'h02; // Index of inversion register.
                        3: data_in <= 8'h00; // 0xF0 by default, we want 0x00

                        // 2) Set current command register to input port.
                        4: cmd <= I2CMASTER_START;
                        5: begin
                            data_in <= 8'h30;
                            cmd <= I2CMASTER_WRITE;
                        end
                        6: data_in <= 8'h00; // Index of input port register

                        // 3) Read input port register.
                        7: cmd <= I2CMASTER_START;
                        8: begin
                            data_in <= 8'h31;
                            cmd <= I2CMASTER_WRITE;
                        end
                        9: cmd <= I2CMASTER_READ;

                        // 4) Save the result.
                        10: begin
                            jack <= data_out;
                            cmd <= I2CMASTER_STOP;
                            i2c_state <= I2C_LED1;
                            delay_cnt <= 0;
                        end
                        default: begin
                            // do nothing
                        end
                    endcase
                    i2c_config_pos <= i2c_config_pos + 1;
                    ack_in <= 1'b1;
                    stb <= 1'b1;
                end
                default: begin
                    i2c_state <= I2C_IDLE;
                end
            endcase
        end else begin
            stb <= 1'b0;
        end
    end
end

i2c_master #(.DW(4)) i2c_master_inst(
    .scl_oe(scl_oe),
    .scl_i(scl_i),
    .sda_oe(sda_oe),
    .sda_i(sda_i),

    .data_in(data_in),
    .ack_in(ack_in),
    .cmd(cmd),
    .stb(stb),

    .data_out(data_out),
    .ack_out(ack_out),
    .err_out(err_out),

    .ready(ready),

    .clk(clk),
    .rst(rst)
);

endmodule
