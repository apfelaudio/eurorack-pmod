module transpose #(
    parameter W = 16,
    parameter FP_OFFSET = 2,
    parameter WINDOW = 512,
    parameter XFADE = 64
)(
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output logic signed [W-1:0] sample_out0,
    output logic signed [W-1:0] sample_out1,
    output logic signed [W-1:0] sample_out2,
    output logic signed [W-1:0] sample_out3
);

logic [15:0] d = 0;
logic [8:0] delay;
assign delay = d[9:1];
always_ff @(posedge sample_clk) begin
    // This value -1 is actually the 'pitch shift' amount.
    d <= d - 1;
end

logic signed [W-1:0] delay_out0;
logic signed [W-1:0] delay_out1;

delayline delay_0(
    .sample_clk(sample_clk),
    .delay(10'(delay)),
    .in(sample_in0),
    .out(delay_out0)
);

delayline delay_1(
    .sample_clk(sample_clk),
    .delay(10'(delay)+WINDOW),
    .in(sample_in0),
    .out(delay_out1)
);

logic [7:0] env0;
logic [7:0] env1;
logic signed [7:0] env0_reg;
logic signed [7:0] env1_reg;

always_ff @(posedge sample_clk) begin
    if (delay < XFADE) begin
        env0 <= delay[7:0];
        env1 <= (XFADE-1) - delay[7:0];
    end else begin
        env0 <= XFADE-1;
        env1 <= 0;
    end
    env0_reg <= env0;
    env1_reg <= env1;

    // TODO: shift based on # bits in crossfade
    sample_out0 <= 16'((32'(delay_out0) * 32'(env0_reg)) >>> 7) +
                   16'((32'(delay_out1) * 32'(env1_reg)) >>> 7);
end

endmodule
