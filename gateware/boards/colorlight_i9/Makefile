PROJ = top

DEVICE = 45k
PACKAGE = CABGA381
SPEEDGRADE = 6
PIN_DEF = ./boards/colorlight_i9/pinmap.lpf
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE)

include ./mk/common.mk
include ./mk/ecp5.mk

# Just re-use the i5 sysmgr implementation as the i9
# also just uses a 25MHz clock.
ADD_SRC = boards/colorlight_i5/sysmgr.v \
		  $(SRC_COMMON)

prog: $(BUILD)/$(PROJ).bin
	openFPGALoader -b colorlight-i9 $(BUILD)/$(PROJ).bin
