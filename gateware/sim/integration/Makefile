SIM ?= icarus
TOPLEVEL_LANG ?= verilog
TOPLEVEL = top
VERILOG_SOURCES = ../../top.sv \
				  ../../eurorack_pmod.sv \
				  ../../drivers/ak4619.sv \
				  ../../cal/cal.sv \
				  ../../boards/icebreaker/sysmgr.v \
				  ../../drivers/pmod_i2c_master.sv \
				  ../../external/no2misc/rtl/i2c_master.v \
				  ../../cal/debug_uart.sv \
				  ../../external/no2misc/rtl/uart_tx.v \
				  ../../cores/pitch_shift_migen.sv

MODULE = tb_integration
COMPILE_ARGS += -DSELECTED_DSP_CORE=pitch_shift_migen -pfileline=1

include $(shell cocotb-config --makefiles)/Makefile.sim
