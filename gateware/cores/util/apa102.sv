// Simple verilog module to control an APA102 LED strip.

`default_nettype none

module apa102 (
  input logic clk,
  input logic reset,
  output logic led_data,
  output logic led_clk,
  input logic [7:0] pixel_red,
  input logic [7:0] pixel_green,
  input logic [7:0] pixel_blue,
  input logic [1:0] cmd,
  output logic busy,
  input logic strobe
);

  // Command codes
  localparam CMD_NONE = 2'b00;
  localparam CMD_SOF = 2'b01;
  localparam CMD_PIXEL = 2'b10;
  localparam CMD_EOF = 2'b11;

  // Internal variables
  logic [1:0] cur_cmd;
  logic [31:0] pixel_latch;
  logic [7:0] bit_counter;

  always_ff @(posedge clk or posedge reset)
  begin
    if(reset)
    begin
      led_clk <= 0;
      busy <= 0;
      bit_counter <= 0;
      cur_cmd <= CMD_NONE;
      led_data <= 0;
      pixel_latch <= 32'b0;
    end
    else if(strobe && !busy)
    begin
      busy <= 1;
      cur_cmd <= cmd;
      case(cmd)
        CMD_SOF: begin
          led_data <= 1'b0;
          bit_counter <= 32;
        end

        CMD_PIXEL: begin
          led_data <= 1'b1;
          pixel_latch <= {8'b11111111, pixel_blue, pixel_green, pixel_red};
          bit_counter <= 32;
        end

        CMD_EOF: begin
          led_data <= 1'b1;
          bit_counter <= 128;
        end

        default: begin
          busy <= 0;
        end
      endcase
    end
    else if(bit_counter != 0)
    begin
      led_clk <= !led_clk;
      // Transition on falling edge
      if (!led_clk) begin
          bit_counter <= bit_counter - 1;
      end
      if (cur_cmd == CMD_PIXEL)
      begin
        led_data <= pixel_latch[bit_counter-1];
      end
    end
    else if(bit_counter == 0)
    begin
        busy <= 1'b0;
        cur_cmd <= CMD_NONE;
    end
  end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("apa102.vcd");
  $dumpvars;
  #1;
end
`endif

endmodule

