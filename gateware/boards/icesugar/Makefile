PROJ = top

DEVICE = up5k
PACKAGE = sg48
PIN_DEF = ./boards/icesugar/pinmap.pcf
# UART: 1Mbaud
ADD_DEFINES = -DSELECTED_DSP_CORE=$(CORE) -DINVERT_BUTTON=1 -DDEBUG_UART_CLKDIV=12

# IceSugar devices load firmware via an exposed USB Mass Storage device.
# Assume the OS has mounted it here.
ICELINK_DIRECTORY=/media/$(USER)/iCELink

include ./mk/common.mk
include ./mk/ice40.mk

ADD_SRC = boards/icebreaker/sysmgr.v \
		  $(SRC_COMMON)

prog: $(BUILD)/$(PROJ).bin
	@if [ ! -d $(ICELINK_DIRECTORY) ] ; then \
		echo "Can't find iCELink storage device" 1>&2 ; \
		exit 1 ; \
	fi ; \
	if ! cp $(BUILD)/$(PROJ).bin $(ICELINK_DIRECTORY) ; then \
		echo "failed to install bitstream" 1>&2 ; \
		exit 1 ; \
	fi ; \
	echo "Bitstream installed to $(ICELINK_DIRECTORY)" 1>&2

