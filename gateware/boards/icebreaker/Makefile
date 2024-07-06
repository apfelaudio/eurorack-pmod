PROJ = top

DEVICE = up5k
PACKAGE = sg48
PIN_DEF = ./boards/icebreaker/pinmap.pcf
# UART: 1Mbaud
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1 -DDEBUG_UART_CLKDIV=12

include ./mk/common.mk
include ./mk/ice40.mk

ADD_SRC = boards/icebreaker/sysmgr.v \
		  $(SRC_COMMON)

prog: $(BUILD)/$(PROJ).bin
	iceprog $(BUILD)/$(PROJ).bin
