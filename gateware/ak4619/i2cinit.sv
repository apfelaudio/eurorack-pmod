// Super simple I2C transciever that can only clock out data.
//
// Currently only used for initializing the registers in the AK4619 on boot.

`default_nettype none

module i2cinit #(
    // File and length of i2c bytes to write to the slave.
    parameter     F_PATH  = "ak4619-cfg.hex",
    parameter int N_BYTES = 6'h17,
    // How long to wait after init before starting I2C TX.
    parameter int N_WAIT_CYCLES = 16'hFF
)(
    input     clk, // 2x i2c clock
    // Note: outputs are NOT tristated on HI, this should be handled
    // in a parent module depending on the output pin topology.
    output    scl,
    output    sda_out
);

localparam I2CINIT_WAIT  = 3'd0,
           I2CINIT_START = 3'd1, // Issue start condition
           I2CINIT_WRITE = 3'd2, // Write a byte
           I2CINIT_ACK   = 3'd3, // Check for an ACK
           I2CINIT_STOP  = 3'd4,
           I2CINIT_DONE  = 3'd5;

logic [7:0] i2c_bytes [0:N_BYTES-1];
initial $readmemh(F_PATH, i2c_bytes);

logic [2:0] i2cinit_state = I2CINIT_WAIT;

logic [15:0] wait_cycles    = 16'd0;
logic [7:0] cur_byte        = 8'd0;
logic [2:0] cur_shift       = 3'd0;
logic clk_cnt               = 1'b0;
logic clk_scl               = 1'b0;
logic clk_sda               = 1'b0;
logic scl_en                = 1'b0;
logic sda_wr                = 1'b1;
logic sda_startstop         = 1'b1;

assign scl = scl_en ? clk_scl : 1'b1;
assign sda_out = ~(~sda_wr || ~sda_startstop);

always_ff @(posedge clk) begin
    clk_cnt <= clk_cnt + 1;
    if (clk_cnt == 0) begin
        clk_scl <= ~clk_scl;
        if (clk_scl == 1'b1) begin
            if (i2cinit_state == I2CINIT_DONE) begin
                scl_en <= 1'b0;
            end
        end
    end else begin
        clk_sda <= ~clk_sda;
        if (clk_sda == 1'b1) begin
            case (i2cinit_state)
                I2CINIT_WAIT: begin
                    wait_cycles = wait_cycles + 1;
                    if (wait_cycles == N_WAIT_CYCLES) begin
                        i2cinit_state <= I2CINIT_START;
                    end
                end
                I2CINIT_START, I2CINIT_WRITE: begin
                    if (i2cinit_state == I2CINIT_START) begin
                        i2cinit_state <= I2CINIT_WRITE;
                    end
                    cur_shift <= cur_shift + 1;
                    if (cur_shift == 3'd7) begin
                        cur_byte <= cur_byte + 1;
                        i2cinit_state <= I2CINIT_ACK;
                    end
                    sda_wr <= 1'b1 & (i2c_bytes[cur_byte] >> (7-cur_shift));
                end
                I2CINIT_ACK: begin
                    sda_wr <= 1'b1;
                    if (cur_byte == N_BYTES) begin
                        i2cinit_state <= I2CINIT_STOP;
                    end else begin
                        i2cinit_state <= I2CINIT_WRITE;
                    end
                end
                I2CINIT_STOP: begin
                    i2cinit_state <= I2CINIT_DONE;
                    sda_startstop <= 1'b0;
                end
                I2CINIT_DONE: begin
                    // TODO: Stop re-sending on success?
                    wait_cycles <= 0;
                    cur_byte    <= 8'd0;
                    cur_shift   <= 3'd0;
                    i2cinit_state <= I2CINIT_WAIT;
                end
            endcase
        end else begin
            if (i2cinit_state == I2CINIT_START) begin
                scl_en <= 1'b1;
                sda_startstop <= 1'b0;
            end else begin
                sda_startstop <= 1'b1;
            end
        end
    end
end

endmodule
