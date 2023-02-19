PROJ = top
ADD_SRC = ak4619/i2cinit.sv \
		  ak4619/ak4619.sv \
		  external/no2misc/rtl/uart_tx.v \
		  cal/cal.sv \
		  cal/cal_uart.sv \
		  cores/clkdiv.sv \
		  cores/seqswitch.sv \
		  cores/sampler.sv \
		  cores/bitcrush.sv \
		  cores/vca.sv \
		  cores/vco.sv \
		  cores/delay_raw.sv \
		  cores/delayline.sv \
		  cores/transpose.sv \
		  cores/pitch_shift.sv \
		  cores/echo.sv \
		  cores/stereo_echo.sv \
		  cores/filter.sv \
		  cores/filter/filter_svf_pipelined.sv

PIN_DEF = mk/icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48

prog: iceprog

include ./mk/main.mk
