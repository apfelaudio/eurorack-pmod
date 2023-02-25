// Driver for all I2C traffic to/from the `eurorack-pmod`.

`default_nettype none

module pmod_i2c_master #(
    parameter CODEC_CFG  = "ak4619-cfg.hex",
    parameter CODEC_CFG_BYTES = 16'h17
)(
    input  clk,
    input  rst,
	output scl_oe,
	input  scl_i,
	output sda_oe,
	input  sda_i
);

// Overall state machine of this core.
// Most of these will not be used until hardware R3.
localparam I2C_INIT          = 4'h0,
           I2C_INIT_CAL      = 4'h1,
           I2C_INIT_JACK     = 4'h2,
           I2C_INIT_LED      = 4'h3,
           I2C_INIT_CODEC1   = 4'h4,
           I2C_INIT_CODEC2   = 4'h5,
           I2C_UPDATE_LEDS   = 4'h6,
           I2C_UPDATE_JACK   = 4'h7,
           I2C_IDLE          = 4'h8;


logic [3:0] i2c_state = I2C_INIT;

// Logic for startup configuration of CODEC over I2C.
logic [7:0] codec_config [0:CODEC_CFG_BYTES-1];
initial $readmemh(CODEC_CFG, codec_config);
logic [15:0] codec_config_pos = 0;

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

always_ff @(posedge clk) begin
    if (rst) begin
        i2c_state <= I2C_INIT_CODEC1;
        codec_config_pos <= 0;
    end else begin
        if (ready && ~stb) begin
            case (i2c_state)
                I2C_INIT_CODEC1: begin
                    cmd <= I2CMASTER_START;
                    stb <= 1'b1;
                    i2c_state <= I2C_INIT_CODEC2;
                end
                I2C_INIT_CODEC2: begin
                    // Shift out all bytes in the CODEC configuration in
                    // one long transaction until we are finished.
                    if (codec_config_pos != CODEC_CFG_BYTES) begin
                        data_in <= codec_config[5'(codec_config_pos)];
                        cmd <= I2CMASTER_WRITE;
                        codec_config_pos <= codec_config_pos + 1;
                    end else begin
                        cmd <= I2CMASTER_STOP;
                        i2c_state <= I2C_IDLE;
                    end
                    ack_in <= 1'b1;
                    stb <= 1'b1;
                end
                default: i2c_state <= I2C_IDLE;
            endcase
        end else begin
            stb <= 1'b0;
        end
    end
end

i2c_master #(.DW(6)) i2c_master_inst(
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
