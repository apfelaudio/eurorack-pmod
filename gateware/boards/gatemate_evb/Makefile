PROJ = top

PIN_DEF = ./boards/gatemate_evb/pinmap.ccf
# UART: 1Mbaud
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1 -DDEBUG_UART_CLKDIV=12

include ./mk/common.mk
include ./mk/gatemate.mk

ADD_SRC = boards/gatemate_evb/sysmgr.v \
		  $(SRC_COMMON)
