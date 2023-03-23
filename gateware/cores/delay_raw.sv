// Toy delay example using raw BRAM instantiation.
//
// This exists to show you how a RAM tile is instantiated under
// the hood on iCE40 to give you a deeper look at what's synthesized.
// For echo effects, you should check out the `stereo_echo.sv` core and
// its implementation in `echo.sv` and `delayline.sv`.
//
// Given input audio on input 0, delay and/or decimate it.
//
// This core saves incoming samples in a circular buffer, and
// plays them back a fixed point in time later. There is no
// self-feedback, this is just a delay by N samples.
//
// Mapping:
// - Input 0: Audio input
// - Output 0: Audio input (mirrored)
// - Output 0: Audio input (delayed + decimated)

module delay_raw #(
    parameter W = 16,
    parameter FP_OFFSET = 2,
    // Decimate sample rate by 2^^DECIMATE before writes/reads to
    // delay buffer - creates a longer delay and sample rate reduction
    // at the same time (given delay buffer size stays constant).
    parameter DECIMATE = 4
)(
    input clk,
    input sample_clk,
    input signed [W-1:0] sample_in0,
    input signed [W-1:0] sample_in1,
    input signed [W-1:0] sample_in2,
    input signed [W-1:0] sample_in3,
    output signed [W-1:0] sample_out0,
    output signed [W-1:0] sample_out1,
    output signed [W-1:0] sample_out2,
    output signed [W-1:0] sample_out3,
    input [7:0] jack
);

// Data to write/read to delay buffer.
logic signed [W-1:0] rdata;
logic signed [W-1:0] wdata;

// By limiting the extent of these addresses in the delay buffer, we
// can shorten the delay time. The read address always sits 255
// positions behind the write address in a circular buffer fashion.
logic signed [7:0] raddr = 1;
logic signed [7:0] waddr = 0;

// Increment position in delay buffer when this hits 0.
logic [DECIMATE:0] sample_skip = 0;

always_ff @(posedge sample_clk) begin
    if (sample_skip == 0) begin
        raddr <= raddr + 1;
        waddr <= waddr + 1;
        wdata <= sample_in0;
    end
    sample_skip <= sample_skip + 1;
end

assign sample_out0 = sample_in0;
assign sample_out1 = rdata;

// Raw instantiation of an ICE40 RAM primitive. We could do this using
// pure Verilog which would be synthesized to this, but it's interesting
// to have a mental picture of what the hardware looks like.
//
// You can easily do this without raw instantiation. See `delayline.sv`.
SB_RAM40_4K #(
    // MODE 0: 256x16bits == 256 samples delay buffer.
    .WRITE_MODE(0),
    .READ_MODE(0)
) ice40_ram4k (
    .RDATA(rdata),
    .RADDR({3'b000, raddr}),
    .RCLK(sample_clk),
    .RCLKE(1'b1),
    .RE(1'b1),
    .WDATA(wdata),
    .WADDR({3'b000, waddr}),
    .MASK(16'h0),
    .WCLK(clk),
    .WCLKE(1'b1),
    .WE(1'b1)
);

endmodule
