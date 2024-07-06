PROJ = top

DEVICE = um5g-85k
PACKAGE = CABGA554
SPEEDGRADE = 8
PIN_DEF = ./boards/ecpix5/pinmap.lpf
# UART: 1Mbaud
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1 -DDEBUG_UART_CLKDIV=12

include ./mk/common.mk
include ./mk/ecp5.mk

ADD_SRC = boards/ecpix5/sysmgr.v \
		  $(SRC_COMMON)

prog: $(BUILD)/$(PROJ).bin
	openFPGALoader -b ecpix5 $(BUILD)/$(PROJ).bin
