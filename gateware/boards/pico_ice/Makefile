PROJ = top

DEVICE = up5k
PACKAGE = sg48
PIN_DEF = ./boards/pico_ice/pinmap.pcf
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1 -DINTERNAL_CLOCK=1

include ./mk/common.mk
include ./mk/ice40.mk

ADD_SRC = boards/pico_ice/sysmgr.v \
		  $(SRC_COMMON)
