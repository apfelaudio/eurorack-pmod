PROJ = top

PIN_DEF = ./boards/gatematea1_evb/pinmap.ccf
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1

include ./mk/common.mk
include ./mk/gatemate.mk

ADD_SRC = boards/gatematea1_evb/sysmgr.v \
		  $(SRC_COMMON)
