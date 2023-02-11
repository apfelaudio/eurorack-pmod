module delayline #(
    parameter W = 16,
    parameter MAX_DELAY = 1024
)(
    input sample_clk,
    input [$clog2(MAX_DELAY)-1:0] delay,
    input signed [W-1:0] in,
    output signed [W-1:0] out
);

logic signed [W-1:0] rdata;

logic [$clog2(MAX_DELAY)-1:0] raddr = 1;
logic [$clog2(MAX_DELAY)-1:0] waddr = 0;

logic signed [W-1:0] bram[MAX_DELAY];

always_ff @(posedge sample_clk) begin
    waddr <= waddr + 1;
    raddr <= waddr - delay;
    bram[waddr] <= in;
    rdata <= bram[raddr];
end

assign out = rdata;

endmodule
