// Delay line with real-time adjustable delay from 1 sample up to
// MAX_DELAY samples. MAX_DELAY must be a power of 2, but the
// current amount of delay requested does not need to be.

module delayline #(
    parameter W = 16,
    parameter MAX_DELAY = 1024
)(
    input clk,
    input strobe,
    input [$clog2(MAX_DELAY)-1:0] delay,
    input signed [W-1:0] in,
    output logic signed [W-1:0] out
);

logic [$clog2(MAX_DELAY)-1:0] raddr = 1;
logic [$clog2(MAX_DELAY)-1:0] waddr = 0;

logic signed [W-1:0] bram[MAX_DELAY];

always_ff @(posedge clk) begin
    if (strobe) begin
        waddr <= waddr + 1;
        // This subtraction wraps correctly as long as MAX_DELAY is
        // a power of 2.
        raddr <= waddr - delay;
        bram[waddr] <= in;
        out <= bram[raddr];
    end
end

endmodule
