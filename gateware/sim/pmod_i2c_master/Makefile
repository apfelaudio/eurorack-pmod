SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = ../../drivers/pmod_i2c_master.sv \
				  ../../external/no2misc/rtl/i2c_master.v
MODULE = tb_pmod_i2c_master
COMPILE_ARGS += -DUNIT_TEST

include $(shell cocotb-config --makefiles)/Makefile.sim
