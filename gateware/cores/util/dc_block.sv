// Simple DC blocker.

module dc_block #(
    parameter W = 16
)(
    input sample_clk,
    input signed [W-1:0] sample_in,
    output signed [W-1:0] sample_out
);

// Equation for a simple DC blocker:
// y_k = (x_k - x_{k-1}) + alpha * y_{k-1}
// Here we set alpha to (255 / 256) ~= 0.995

localparam SHIFT = 8;

logic signed [W-1:0] x_k;
logic signed [W-1:0] x_k1;
logic signed [W-1:0] y_k1;

assign x_k = sample_in;
assign sample_out = y_k1;

always_ff @(posedge sample_clk) begin
    x_k1 <= x_k;
    // Cheaper way to set alpha to ((1 << SHIFT) - 1) / SHIFT ~= 0.99
    y_k1 <= (x_k - x_k1) + 16'((32'(y_k1) * 32'((1 << SHIFT) - 1)) >>> SHIFT);
end

endmodule
