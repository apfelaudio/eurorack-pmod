// Driver for all I2C traffic to/from the `eurorack-pmod`.

`default_nettype none

module pmod_i2c_master #(
    parameter CODEC_CFG  = "ak4619-cfg.hex",
    parameter CODEC_CFG_BYTES = 16'd23,
    parameter LED_CFG  = "pca9635-cfg.hex",
    parameter LED_CFG_BYTES = 16'd26
)(
    input  clk,
    input  rst,
	output scl_oe,
	input  scl_i,
	output sda_oe,
	input  sda_i,

    input signed [7:0] led0,
    input signed [7:0] led1,
    input signed [7:0] led2,
    input signed [7:0] led3,
    input signed [7:0] led4,
    input signed [7:0] led5,
    input signed [7:0] led6,
    input signed [7:0] led7,

    output logic [7:0] jack
);

// Overall state machine of this core.
// Most of these will not be used until hardware R3.
localparam I2C_DELAY1        = 0,
           I2C_INIT_CODEC1   = 1,
           I2C_INIT_CODEC2   = 2,
           I2C_LED1          = 3,
           I2C_LED2          = 4,
           I2C_JACK1         = 5,
           I2C_JACK2         = 6,
           I2C_IDLE          = 7;


logic [3:0] i2c_state = I2C_DELAY1;

// Index into i2c config memories
logic [15:0] i2c_config_pos = 0;

// Logic for startup configuration of CODEC over I2C.
logic [7:0] codec_config [0:CODEC_CFG_BYTES-1];
initial $readmemh(CODEC_CFG, codec_config);

// Logic for startup configuration of LEDs over I2C.
logic [7:0] led_config [0:LED_CFG_BYTES-1];
initial $readmemh(LED_CFG, led_config);
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

// Inbound signals from `i2c_master core.
logic [7:0] data_out;
logic       ack_out;
logic       err_out;
logic       ready;


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
                    if(delay_cnt[17])
                        i2c_state <= I2C_JACK1;
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
                            i2c_state <= I2C_DELAY1;
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

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("pmod_i2c_master.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
