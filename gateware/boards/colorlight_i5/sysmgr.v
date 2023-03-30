`default_nettype none

module sysmgr (
    // Assumed 25Mhz for Colorlight i5.
	input  wire clk_in,
	input  wire rst_in,
	output wire clk_12m,
	output wire rst_out
);

// Signals
wire clk_fb;

wire pll_lock;
wire pll_reset;

wire rst_i;
reg [7:0] rst_cnt;

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
        .CLKI_DIV(1),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(24),
        .CLKOP_CPHASE(9),
        .CLKOP_FPHASE(0),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(50),
        .CLKOS_CPHASE(0),
        .CLKOS_FPHASE(0),
        .FEEDBK_PATH("INT_OP"),
        .CLKFB_DIV(1)
) pll_i (
        .RST(pll_reset),
        .STDBY(1'b0),
        .CLKI(clk_in),
        .CLKOS(clk_12m),
        .CLKFB(clk_fb),
        .CLKINTFB(clk_fb),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(pll_lock)
);

// PLL reset generation
assign pll_reset = rst_in;
// Logic reset generation
always @(posedge clk_in)
    if (!pll_lock)
        rst_cnt <= 8'h0;
    else if (~rst_cnt[7])
        rst_cnt <= rst_cnt + 1;

assign rst_i = ~rst_cnt[7];

assign rst_out = rst_i;

endmodule // sysmgr
