module i2cinit (
    input    clk,
    inout    sda,
    output   scl
);

parameter N_REG = 6'h15;

reg [7:0] init_reg [0:N_REG];
initial $readmemh("ak4619-cfg/ak4619-cfg.hex", init_reg);

reg [5:0] cur_reg_counter = 0;
reg [7:0] cur_reg_value;

always @(posedge clk) begin
    cur_reg_value <= init_reg[cur_reg_counter];
    cur_reg_counter <= cur_reg_counter + 1;
end

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("i2cinit.vcd");
  $dumpvars;
  #1;
end
`endif
endmodule
