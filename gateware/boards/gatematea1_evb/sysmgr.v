`default_nettype none

module sysmgr (
	input  wire clk_in,
	input  wire rst_in,
	output wire clk_256fs,
	output wire clk_fs,
	output wire rst_out
);

wire clk_fb;
wire pll_lock;
wire pll_reset;
wire rst_i;

reg [7:0] rst_cnt;
reg [7:0] clkdiv;

assign pll_reset = rst_in;
assign rst_i = ~rst_cnt[7];
assign rst_out = rst_i;
assign clk_fs = clkdiv[7];

`ifndef VERILATOR_LINT_ONLY

wire clk270, clk180, clk90, usr_ref_out, usr_pll_lock_stdy;

CC_PLL #(
    .REF_CLK("10.0"),    // reference input in MHz
    .OUT_CLK("12.0"),    // pll output frequency in MHz
    .PERF_MD("SPEED"), // LOWPOWER, ECONOMY, SPEED
    .LOW_JITTER(1),      // 0: disable, 1: enable low jitter mode
    .CI_FILTER_CONST(2), // optional CI filter constant
    .CP_FILTER_CONST(4)  // optional CP filter constant
) pll_inst (
    .CLK_REF(clk_in), .CLK_FEEDBACK(1'b0), .USR_CLK_REF(1'b0),
    .USR_LOCKED_STDY_RST(1'b0), .USR_PLL_LOCKED_STDY(usr_pll_lock_stdy), .USR_PLL_LOCKED(pll_lock),
    .CLK270(clk270), .CLK180(clk180), .CLK90(clk90), .CLK0(clk_256fs), .CLK_REF_OUT(usr_ref_out)
);

`endif

always @(posedge clk_in)
    if (rst_in || ~usr_pll_lock_stdy)
        rst_cnt <= 8'h0;
    else if (~rst_cnt[7])
        rst_cnt <= rst_cnt + 1;

always @(posedge clk_256fs)
    if (rst_i)
        clkdiv <= 8'h00;
    else
        clkdiv <= clkdiv + 1;

endmodule // sysmgr
