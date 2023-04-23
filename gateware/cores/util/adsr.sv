module ad_envelope (
    parameter W = 16
)(
    input logic clk,
    input logic reset,
    output reg [W-1:0] output_level
);

// Constants
localparam ATTACK  = 4'h0;
localparam DECAY   = 4'h1;
localparam IDLE    = 4'h2;

localparam OUT_MAX       = W'h7FFF;
localparam ATTACK_TIME   = W'd1000;
localparam DECAY_TIME    = W'd2000;

localparam ATTACK_COEFF  = OUT_MAX / ATTACK_TIME;
localparam DECAY_COEFF   = (OUT_MAX - SUSTAIN_LEVEL) / DECAY_TIME;

logic [3:0] phase;
logic [W-1:0] elapsed_time;

// Shared multiplier
logic [W-1:0] mult_operand_a;
logic [W-1:0] mult_operand_b;
logic [2*W-1:0] mult_result;

assign mult_result = mult_operand_a * mult_operand_b;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        output_level <= 0;
        elapsed_time <= 0;
    end else begin

        // Calculate AD envelope phase
        if (elapsed_time < attack_time) begin
            phase <= ATTACK;
        end else if (elapsed_time < (attack_time + decay_time)) begin
            phase <= DECAY;
        else
            phase <= IDLE;
        end

        // Calculate output level based on phase
        case (phase)
            ATTACK: begin
                mult_operand_a <= elapsed_time;
                mult_operand_b <= ATTACK_COEFF;
                output_level <= mult_result[2*W-1:W];
                elapsed_time <= elapsed_time + 1;
            end
            DECAY: begin
                mult_operand_a <= elapsed_time - ATTACK_TIME;
                mult_operand_b <= DECAY_COEFF;
                output_level <= OUT_MAX - mult_result[2*W-1:W];
                elapsed_time <= elapsed_time + 1;
            end
            IDLE: begin
                output_level <= 0;
            end
        endcase
    end
end

endmodule
