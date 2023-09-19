SRC_COMMON = eurorack_pmod.sv \
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
		     cores/pitch_shift.sv \
		     cores/stereo_echo.sv \
		     cores/filter.sv \
		     cores/util/filter/karlsen_lpf_pipelined.sv \
		     cores/util/filter/karlsen_lpf.sv \
		     cores/util/transpose.sv \
		     cores/util/echo.sv \
		     cores/util/delayline.sv \
			 cores/util/dc_block.sv
