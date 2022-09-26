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

// Calibrated samples represent millivolts in 16 bits, last 2 bits are fractional.
`define FROM_MV(value) (value <<< 2)

// Input and output voltage thresholds.
`define SCHMITT_HI `FROM_MV(2000)
`define SCHMITT_LO `FROM_MV(500)
`define OUT_HI     `FROM_MV(5000)
`define OUT_LO     `FROM_MV(0)

// Keeping track of last input state effectively behaves as schmitt inputs.
reg last_state_hi = 1'b0;
reg [3:0] div = 0;

always @(posedge sample_clk) begin
    if (sample_in0 > `SCHMITT_HI && !last_state_hi) begin
        last_state_hi <= 1'b1;
        // Increment count on every rising edge.
        div <= div + 1;
    end else if (sample_in0 < `SCHMITT_LO  &&  last_state_hi) begin
        last_state_hi <= 1'b0;
    end
end

// output 0 mirrors input 0, outputs 1-3 are /2, /4, /8
assign sample_out0 = sample_in0;
assign sample_out1 = div[0] ? `OUT_HI : `OUT_LO;
assign sample_out2 = div[1] ? `OUT_HI : `OUT_LO;
assign sample_out3 = div[2] ? `OUT_HI : `OUT_LO;

endmodule
