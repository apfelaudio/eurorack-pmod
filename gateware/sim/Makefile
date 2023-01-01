SIM ?= icarus
TOPLEVEL_LANG ?= verilog
TOPLEVEL = top
VERILOG_SOURCES = ../ak4619/ak4619.sv \
                  ../ak4619/i2cinit.sv \
                  ../util/uart_tx.v \
                  ../util/uart_baud_tick_gen.v \
                  ../cal/cal.sv \
                  ../cores/clkdiv.sv \
                  ../cores/bitcrush.sv \
                  ../cores/seqswitch.sv \
				  ../top.sv
MODULE = tb_ak4619

include $(shell cocotb-config --makefiles)/Makefile.sim
