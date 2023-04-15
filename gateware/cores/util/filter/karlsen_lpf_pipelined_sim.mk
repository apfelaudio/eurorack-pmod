SIM ?= icarus
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = karlsen_lpf_pipelined.sv
MODULE = tb_karlsen_lpf

include $(shell cocotb-config --makefiles)/Makefile.sim
