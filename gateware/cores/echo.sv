// Simple digital echo with adjustable delay and feedback.

module echo #(
    parameter W = 16,
    parameter ECHO_MAX_SAMPLES = 1024
)(
    input sample_clk,
    input signed [W-1:0] sample_in,
    output logic signed [W-1:0] sample_out
);

localparam DELAY_BITS = $clog2(ECHO_MAX_SAMPLES);
// These 2 parameters could easily just be input signals.
localparam DELAY = DELAY_BITS'(ECHO_MAX_SAMPLES-1);
localparam FEEDBACK_SHIFT = 1;

logic signed [W-1:0] delay_in;
logic signed [W-1:0] delay_out;

delayline #(W, ECHO_MAX_SAMPLES) delay_0 (
    .sample_clk(sample_clk),
    .delay(DELAY),
    .in(delay_in),
    .out(delay_out)
);

always_ff @(posedge sample_clk) begin
    delay_in <= (sample_in >>> 1) + (delay_out >>> FEEDBACK_SHIFT);
    sample_out <= delay_out;
end

endmodule
