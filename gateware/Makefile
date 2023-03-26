PROJ = top
ADD_SRC = drivers/pmod_i2c_master.sv \
		  drivers/ak4619.sv \
		  external/no2misc/rtl/uart_tx.v \
		  external/no2misc/rtl/i2c_master.v \
		  external/ice40_sysmgr.v \
		  cal/cal.sv \
		  cal/debug_uart.sv \
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
		  cores/filter/filter_svf_pipelined.sv \
		  pmod1.sv \
		  pmod2.sv

PIN_DEF = mk/icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48

prog: iceprog

include ./mk/main.mk
