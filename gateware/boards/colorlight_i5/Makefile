PROJ = top

CORE ?= mirror

DEVICE = 25k
PACKAGE = CABGA381
PIN_DEF = ./boards/colorlight_i5/pinmap.lpf
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE)

include ./mk/common.mk
include ./mk/ecp5.mk

ADD_SRC = boards/colorlight_i5/sysmgr.v \
		  $(SRC_COMMON)

prog: $(BUILD)/$(PROJ).bin
	openFPGALoader -b colorlight-i5 $(BUILD)/$(PROJ).bin
