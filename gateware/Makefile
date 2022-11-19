PROJ = top
ADD_SRC = ak4619/i2cinit.sv \
		  ak4619/ak4619.sv \
		  util/uart_baud_tick_gen.v \
		  util/uart_tx.v \
		  cal/input_cal.sv \
		  cal/output_cal.sv \
		  cores/clkdiv.sv \
		  cores/sampler.sv \
		  cores/bitcrush.sv \
		  cores/vca.sv \
		  cores/filter.sv \
		  cores/filter/filter_svf_pipelined.sv

PIN_DEF = mk/icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48

prog: iceprog

include ./mk/main.mk
