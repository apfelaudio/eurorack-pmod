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

`default_nettype none

module cal #(
    parameter integer W = 16, // sample width
    parameter CAL_MEM_FILE = "cal_mem.hex"
)(
    input clk, // 24Mhz
    input sample_clk,
    input signed [W-1:0] in0,
    input signed [W-1:0] in1,
    input signed [W-1:0] in2,
    input signed [W-1:0] in3,
    input signed [W-1:0] in4,
    input signed [W-1:0] in5,
    input signed [W-1:0] in6,
    input signed [W-1:0] in7,
    output logic signed [W-1:0] out0,
    output logic signed [W-1:0] out1,
    output logic signed [W-1:0] out2,
    output logic signed [W-1:0] out3,
    output logic signed [W-1:0] out4,
    output logic signed [W-1:0] out5,
    output logic signed [W-1:0] out6,
    output logic signed [W-1:0] out7
);

localparam int N_CHANNELS = 8;

localparam int CAL_ST_ZERO      = 3'd0,
               CAL_ST_MULTIPLY  = 3'd1,
               CAL_ST_CLAMPL    = 3'd2,
               CAL_ST_OUT       = 3'd3,
               CAL_ST_HALT      = 3'd4;

// Only need to clamp negative values as with current hardware it
// is impossible to overflow in the positive direction during cal.
localparam int signed CLAMPL = -32'sd32000;

logic signed [W-1:0]     cal_mem [2*N_CHANNELS];
logic signed [W-1:0]     in      [N_CHANNELS];
logic signed [(2*W)-1:0] out     [N_CHANNELS];
logic        [2:0]       ch      = 0;
logic        [2:0]       state   = CAL_ST_ZERO;
logic               l_sample_clk = 1'd0;

// Calibration memory for 8 channels stored as
// 2 bytes shift, 2 bytes multiply * 8 channels.
initial $readmemh(CAL_MEM_FILE, cal_mem);

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
    end else begin
        ch <= ch + 1;
    end

    case (state)
        CAL_ST_ZERO: begin
            out[ch] <= (in[ch] - cal_mem[{ch, 1'b0}]);
            if (ch == N_CHANNELS-1) state <= CAL_ST_MULTIPLY;
        end
        CAL_ST_MULTIPLY: begin
            out[ch] <= (out[ch] * cal_mem[{ch, 1'b1}]) >>> 10;
            if (ch == N_CHANNELS-1) state <= CAL_ST_OUT;
        end
        CAL_ST_OUT: begin
            // TODO(sebholzapfel): add CLAMPL to pipeline.
            out0  <= out[0] < CLAMPL ? CLAMPL : out[0];
            out1  <= out[1] < CLAMPL ? CLAMPL : out[1];
            out2  <= out[2] < CLAMPL ? CLAMPL : out[2];
            out3  <= out[3] < CLAMPL ? CLAMPL : out[3];
            out4  <= out[4] < CLAMPL ? CLAMPL : out[4];
            out5  <= out[5] < CLAMPL ? CLAMPL : out[5];
            out6  <= out[6] < CLAMPL ? CLAMPL : out[6];
            out7  <= out[7] < CLAMPL ? CLAMPL : out[7];
            state <= CAL_ST_HALT;
        end
        default: begin
            // Halt and do nothing.
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
