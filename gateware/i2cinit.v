module i2cinit (
    input    clk,
    inout    sda,
    output   scl
);

parameter N_BYTES = 6'h17;

// Array of i2c bytes to write to the slave.
reg [7:0] i2c_bytes [0:N_BYTES];
initial $readmemh("ak4619-cfg/ak4619-cfg.hex", i2c_bytes);

reg [5:0] cur_reg_counter = 0;
reg [7:0] cur_reg_value;

localparam I2CINIT_WAIT  = 3'd0,
           I2CINIT_START = 3'd1, // Issue start condition
           I2CINIT_WRITE = 3'd2, // Write a byte
           I2CINIT_ACK   = 3'd3, // Check for an ACK
           I2CINIT_STOP  = 3'd4,
           I2CINIT_DONE  = 3'd5;

reg [2:0] i2cinit_state = I2CINIT_WAIT;

reg clk_cnt = 1'b0;
reg clk_scl = 1'b0;
reg clk_sda = 1'b1;
always @(posedge clk) begin
    clk_cnt <= clk_cnt + 1;
    if (clk_cnt == 0) begin
        clk_scl <= ~clk_scl;
    end else begin
        clk_sda <= ~clk_sda;
    end
end

reg scl_en = 1'b1;
reg sda_en = 1'b1;
reg sda_value = 1'b1;
assign scl = clk_scl && scl_en;
assign sda = sda_value || ~sda_en; // If sda is not enabled, output high

reg [15:0] wait_cycles = 16'd0;
reg [7:0] cur_byte  = 8'd0;
reg [2:0] cur_shift = 3'd0;
reg [7:0] cur_byte_value = 8'd0;
always @(posedge clk_sda) begin
    if (i2cinit_state == I2CINIT_WAIT) begin
        // TODO: when to start scl_en?
        wait_cycles = wait_cycles + 1;
        if (wait_cycles == 16'd20) begin
            i2cinit_state <= I2CINIT_START;
        end
    end
    if (i2cinit_state == I2CINIT_WRITE) begin
        sda_en <= 1'b1;
        cur_shift <= cur_shift + 1;
        if (cur_shift == 3'd7) begin
            cur_byte <= cur_byte + 1;
            i2cinit_state <= I2CINIT_ACK;
        end
        sda_value <= 1'b1 & (i2c_bytes[cur_byte] >> (7-cur_shift));
        cur_byte_value <= i2c_bytes[cur_byte];
    end
    if (i2cinit_state == I2CINIT_ACK) begin
        sda_en <= 1'b0;
        i2cinit_state <= I2CINIT_WRITE;
    end
end

always @(negedge clk_sda) begin
    if (i2cinit_state == I2CINIT_START) begin
        sda_en <= 1'b1;
        sda_value <= 1'b0;
        i2cinit_state <= I2CINIT_WRITE;
    end
    if (i2cinit_state == I2CINIT_STOP) begin
        sda_en <= 1'b0;
        i2cinit_state <= I2CINIT_DONE;
    end
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("i2cinit.vcd");
  $dumpvars;
  #1;
end
`endif
endmodule
