PROJ = top
ADD_SRC = eurorack_pmod.sv \
		  drivers/pmod_i2c_master.sv \
		  drivers/ak4619.sv \
		  external/no2misc/rtl/uart_tx.v \
		  external/no2misc/rtl/i2c_master.v \
		  cal/cal.sv \
		  cal/debug_uart.sv \
		  cores/mirror.sv \
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

PIN_DEF = mk/colorlight_i5.lpf
DEVICE = 25k
PACKAGE = CABGA381

include ./mk/main_ecp5.mk

prog: top.bin
	openFPGALoader -b colorlight-i5 top.bin
