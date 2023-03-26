// Clock Divider
//
// Given an input clock source on input 0, produce divided output on Output 0 - 3.
//
// This core also demonstrates using jack detection.
//
// Mapping:
// - Input 0: Clock input (Hi > 2V, Lo < 0.5V)
// - Input 1-3: Not used
// Outputs only become active if jack is inserted:
// - Output 1: Clock / 2 (Hi == 5V, Lo == 0V)
// - Output 2: Clock / 4
// - Output 3: Clock / 8
// - Output 4: Clock / 16

module clkdiv #(
    parameter W = 16,
    parameter FP_OFFSET = 2
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

    // Jack detection inputs.
    input [7:0] jack
);

// Calibrated samples represent millivolts in 16 bits, last 2 bits are fractional.
`define FROM_MV(value) (value <<< FP_OFFSET)

// Input and output voltage thresholds.
localparam SCHMITT_HI = `FROM_MV(2000);
localparam SCHMITT_LO = `FROM_MV(500);
localparam OUT_HI     = `FROM_MV(5000);
localparam OUT_LO     = `FROM_MV(0);

// Keeping track of last input state effectively behaves as schmitt inputs.
logic last_state_hi = 1'b0;
logic [3:0] div = 0;
logic [17:0] deep = 0;
logic last_deep = 0;

always_ff @(posedge sample_clk) begin
    deep <= deep + 1;
    last_deep <= deep[13];
    if (last_deep != deep[13])
        div <= div + 1;
end

assign sample_out0 = (!div[0]) ? OUT_HI : OUT_LO;
assign sample_out1 = (!div[0]) ? OUT_HI : OUT_LO;
assign sample_out2 = (div[1]) ? OUT_HI : OUT_LO;
assign sample_out3 = (div[2]) ? OUT_HI : OUT_LO;

endmodule
