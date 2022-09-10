module clkdiv (
    input clk, // 12Mhz
    input sample_clk,
    input signed [15:0] sample_in0,
    input signed [15:0] sample_in1,
    input signed [15:0] sample_in2,
    input signed [15:0] sample_in3,
    output signed [15:0] sample_out0,
    output signed [15:0] sample_out1,
    output signed [15:0] sample_out2,
    output signed [15:0] sample_out3
);

// Keeping track of last state effectively behaves as schmitt inputs.
reg last_state_hi = 1'b0;
reg [3:0] div = 0;

always @(posedge sample_clk) begin
    if (sample_in0 > 4 * 2000 && !last_state_hi) begin
        last_state_hi <= 1'b1;
        // Increment count on every rising edge.
        div <= div + 1;
    end else if (sample_in0 < 4 * 500  &&  last_state_hi) begin
        last_state_hi <= 1'b0;
    end
end

// output 0 mirrors input 0, outputs 1-3 are /2, /4, /8
// 5V out for HI, 0V out for LO.
assign sample_out0 = sample_in0;
assign sample_out1 = div[0] ? 4 * 5000 : 0;
assign sample_out2 = div[1] ? 4 * 5000 : 0;
assign sample_out3 = div[2] ? 4 * 5000 : 0;

endmodule
