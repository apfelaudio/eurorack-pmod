`default_nettype none

module sysmgr (
    // Assumed 48Mhz for Tiliqua / Soldiercrab R2.0.
	input  wire clk_in,
	input  wire rst_in,
	output wire clk_256fs,
	output wire rst_out
);

wire clk_fb;
wire pll_lock;
wire pll_reset;
wire rst_i;

reg [7:0] rst_cnt;

assign pll_reset = rst_in;
assign rst_i = ~rst_cnt[7];
assign rst_out = rst_i;

`ifndef VERILATOR_LINT_ONLY

// You can re-generate this using `ecppll` tool. Be careful, the default settings
// disable PLLRST_ENA and use a different FEEDBK_PATH, make sure they remain.

(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOS="12" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("ENABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(4),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(50),
        .CLKOP_CPHASE(24),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(1)
) pll_i (
        .RST(pll_reset),
        .STDBY(1'b0),
        .CLKI(clk_in),
        .CLKOP(clk_256fs),
        .CLKFB(clk_256fs),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(pll_lock)
);

`endif

always @(posedge clk_in)
    if (!pll_lock)
        rst_cnt <= 8'h0;
    else if (~rst_cnt[7])
        rst_cnt <= rst_cnt + 1;

endmodule // sysmgr
