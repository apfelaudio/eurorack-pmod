/* Simple state-variable filter from `https://github.com/gundy/tiny-synth`
*  Source path `hdl/filter_svf_pipelined.vh`.
*  The above repository is distributed under the CERN OHL v1.2 */

`ifndef __TINY_SYNTH_SVF_PIPELINED__
`define __TINY_SYNTH_SVF_PIPELINED__

/*
 * State variable filter:
 *  Ref: Musical applications of microprocessors - Chamberlain: pp489+
 *
 * NOTE: this filter should be functionally equivalent to filter_svh, except
 *       that it is pipelined, and requires a higher frequency clock as well
 *       as the sample clock.
 *
 *       This implementation uses only a single 18*18 multiplier, rather than
 *       3, so should save a lot in terms of gate count.
 *
 *       The downside is that the filter takes 4 clock cycles for each sample.
 *
 * This filter provides high-pass, low-pass, band-pass and notch-pass outputs.
 *
 * Tuning parameters are F (frequency), and Q1 of the filter.
 *
 * The relation between F, the cut-off frequency Fc,
 * and the sampling rate, Fs, is approximated by the formula:
 *
 * F = 2π*Fc/Fs
 *
 * F is a 1.17 fixed-point value, and at a sample rate of 250kHz,
 * F ranges from approximately 0.00050 (10Hz) -> ~0.55 (22kHz).
 *
 * Q1 controls the Q (resonance) of the filter.  Q1 is equivalent to 1/Q.
 * Q1 ranges from 2 (corresponding to a Q value of 0.5) down to 0 (Q = infinity)
 */

 /* multiplier module */
 module smul_18x18 (
   input signed [17:0] a,
   input signed [17:0] b,
   output reg signed [35:0] o
 );
   always @(*) begin
    o = a * b;
   end
 endmodule

module filter_svf_pipelined #(
  parameter SAMPLE_BITS = 12
)(
  input  clk,
  input  sample_clk,
  input  signed [SAMPLE_BITS-1:0] in,
  output reg signed [SAMPLE_BITS-1:0] out_highpass,
  output reg signed [SAMPLE_BITS-1:0] out_lowpass,
  output reg signed [SAMPLE_BITS-1:0] out_bandpass,
  output reg signed [SAMPLE_BITS-1:0] out_notch,
  input  signed [17:0] F,  /* F1: frequency control; fixed point 1.17  ; F = 2sin(π*Fc/Fs).  At a sample rate of 250kHz, F ranges from 0.00050 (10Hz) -> ~0.55 (22kHz) */
  input  signed [17:0] Q1  /* Q1: Q control;         fixed point 2.16  ; Q1 = 1/Q        Q1 ranges from 2 (Q=0.5) to 0 (Q = infinity). */
);


  reg signed[SAMPLE_BITS+2:0] highpass;
  reg signed[SAMPLE_BITS+2:0] lowpass;
  reg signed[SAMPLE_BITS+2:0] bandpass;
  reg signed[SAMPLE_BITS+2:0] notch;
  reg signed[SAMPLE_BITS+2:0] in_sign_extended;

  localparam signed [SAMPLE_BITS+2:0] MAX = (2**(SAMPLE_BITS-1))-1;
  localparam signed [SAMPLE_BITS+2:0] MIN = -(2**(SAMPLE_BITS-1));

  `define CLAMP(x) ((x>MAX)?MAX:((x<MIN)?MIN:x[SAMPLE_BITS-1:0]))



  // intermediate values from multipliers
  reg signed [35:0] Q1_scaled_delayed_bandpass;
  reg signed [35:0] F_scaled_delayed_bandpass;
  reg signed [35:0] F_scaled_highpass;




  reg signed [17:0] mul_a, mul_b;
  wire signed [35:0] mul_out;

  smul_18x18 multiplier(.a(mul_a), .b(mul_b), .o(mul_out));

  reg prev_sample_clk;
  reg [2:0] state;

  initial begin
    state = 3'd3;
    in_sign_extended = 0;
    prev_sample_clk = 0;
    highpass = 0;
    lowpass = 0;
    bandpass = 0;
    notch = 0;
  end

  always @(posedge clk) begin
    prev_sample_clk <= sample_clk;
    if (!prev_sample_clk && sample_clk) begin
      // sample clock has gone high, send out previously computed sample
      out_highpass <= `CLAMP(highpass);
      out_lowpass <= `CLAMP(lowpass);
      out_bandpass <= `CLAMP(bandpass);
      out_notch <= `CLAMP(notch);

      // also clock in new sample, and kick off state machine
      in_sign_extended <= { in[SAMPLE_BITS-1], in[SAMPLE_BITS-1], in[SAMPLE_BITS-1], in};
      mul_a <= bandpass;
      mul_b <= Q1;
      state <= 3'd0;
    end

    case (state)
      3'd0: begin
              // Q1_scaled_delayed_bandpass = (bandpass * Q1) >>> 16;
              Q1_scaled_delayed_bandpass <= (mul_out >> 16);
              mul_b <= F;
              state <= 3'd1;
            end
      3'd1: begin
              // F_scaled_delayed_bandpass = (bandpass * F) >>> 17;
              F_scaled_delayed_bandpass = (mul_out >> 17);
              lowpass = lowpass + F_scaled_delayed_bandpass[SAMPLE_BITS+2:0];
              highpass = in_sign_extended - lowpass - Q1_scaled_delayed_bandpass[SAMPLE_BITS+2:0];
              mul_a <= highpass;
              state <= 3'd2;
            end
      3'd2: begin
              F_scaled_highpass = mul_out >> 17;
              bandpass <= F_scaled_highpass[SAMPLE_BITS+2:0] + bandpass;
              notch <= highpass + lowpass;
              state <= 3'd3;
            end
    endcase

    // in_sign_extended = { in[SAMPLE_BITS-1], in[SAMPLE_BITS-1], in[SAMPLE_BITS-1], in};  /* sign-extend the input value to a wider precision */
    // Q1_scaled_delayed_bandpass = (bandpass * Q1) >>> 16;
    // F_scaled_delayed_bandpass = (bandpass * F) >>> 17;
    // lowpass = lowpass + F_scaled_delayed_bandpass[SAMPLE_BITS+2:0];
    // highpass = in_sign_extended - lowpass - Q1_scaled_delayed_bandpass[SAMPLE_BITS+2:0];
    // F_scaled_highpass = (highpass * F) >>> 17;
    // bandpass = F_scaled_highpass[SAMPLE_BITS+2:0] + bandpass;
    // notch = highpass + lowpass;
  end

endmodule

`endif
