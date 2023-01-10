// Calibrator module.
//
// Convert between raw & 'calibrated' samples by removing DC offset
// and scaling for 4 counts / mV (i.e 14.2 fixed-point).
//
// This is essentially implemented as a pipelined 8 channel multiplier
// with 4 channels used for calibrating raw ADC counts and 4 channels
// used for calibrating output DAC counts.
//
// The calibration memory is created by following the calibration process
// documented in `cal.py`. This module only uses a single multiplier for
// all channels such that there are plenty left over for user logic.

module cal (
    input clk, // 24Mhz
    input sample_clk,
    input signed [15:0] in0,
    input signed [15:0] in1,
    input signed [15:0] in2,
    input signed [15:0] in3,
    input signed [15:0] in4,
    input signed [15:0] in5,
    input signed [15:0] in6,
    input signed [15:0] in7,
    output logic signed [15:0] out0,
    output logic signed [15:0] out1,
    output logic signed [15:0] out2,
    output logic signed [15:0] out3,
    output logic signed [15:0] out4,
    output logic signed [15:0] out5,
    output logic signed [15:0] out6,
    output logic signed [15:0] out7
);

localparam CAL_ST_ZERO     = 2'd0,
           CAL_ST_MULTIPLY = 2'd1,
           CAL_ST_HALT     = 2'd2;

logic signed [15:0] cal_mem [0:15];
logic signed [15:0] in      [0:7];
logic signed [31:0] out     [0:7];
logic        [2:0]  ch           = 3'd0;
logic        [1:0]  state        = CAL_ST_ZERO;
logic               l_sample_clk = 1'd0;


// Calibration memory for 8 channels stored as
// 2 bytes shift, 2 bytes multiply * 8 channels.
initial $readmemh("cal_mem.hex", cal_mem);

always_ff @(posedge clk) begin

    // On rising sample_clk.
    if (sample_clk && (l_sample_clk != sample_clk)) begin
        state <= CAL_ST_ZERO;
        ch <= 0;
        in[0] <= in0;
        in[1] <= in1;
        in[2] <= in2;
        in[3] <= in3;
        in[4] <= in4;
        in[5] <= in5;
        in[6] <= in6;
        in[7] <= in7;

        out0  <= out[0];
        out1  <= out[1];
        out2  <= out[2];
        out3  <= out[3];
        out4  <= out[4];
        out5  <= out[5];
        out6  <= out[6];
        out7  <= out[7];
    end else begin
        ch <= ch + 1;
    end

    case (state)
        CAL_ST_ZERO: begin
            out[ch] <= (in[ch] - cal_mem[{ch, 1'b0}]);
            if (ch == 7) state <= CAL_ST_MULTIPLY;
        end
        CAL_ST_MULTIPLY: begin
            out[ch] <= (out[ch] * cal_mem[{ch, 1'b1}]) >>> 10;
            if (ch == 7) state <= CAL_ST_HALT;
        end
    endcase

    l_sample_clk <= sample_clk;
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("cal.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule
