ALL_BOARDS = $(shell ls boards)
ALL_CORES = $(shell basename --suffix=.sv -- cores/*.sv)
ALL_HW_REV = "HW_R31 HW_R33"

CORE ?= mirror

all prog:
ifeq ($(BOARD),)
	@echo "Valid HW_REV values are: $(ALL_HW_REV)".
	@echo "Valid BOARD values are: $(ALL_BOARDS)".
	@echo "Valid CORE values are: $(ALL_CORES)".
	@echo "For example:"
	@echo "  $$ make clean"
	@echo "  $$ # Build bitstream with specific core and program it"
	@echo "  $$ make HW_REV=HW_R33 BOARD=icebreaker CORE=stereo_echo prog"
	@exit 1
endif
ifeq ($(wildcard ./boards/$(BOARD)/Makefile),)
	@echo "Target '$(BOARD)' does not exist in 'boards/'"
	@echo "Valid targets are: $(ALL_BOARDS)".
	@exit 2
endif
ifeq ($(wildcard ./cores/$(CORE).sv),)
	@echo "'$(CORE).sv' does not exist in 'cores/'"
	@echo "Valid targets are: $(ALL_CORES)".
	@exit 3
endif
ifeq ($(HW_REV),)
	@echo "Please specify a eurorack-pmod hardware revision using HW_REV=<>".
	@echo "Valid hardware revisions are: '$(ALL_HW_REV)'".
	@exit 4
endif
	mkdir -p build/$(BOARD)
	# For now we always force a re-build since we can pass different DSP cores
	# through environment vars and we need a re-build to happen in this case.
	$(MAKE) -B -f boards/$(BOARD)/Makefile BUILD=build/$(BOARD) CORE=$(CORE) $(MAKECMDGOALS)

clean:
	rm -rf build/

.SECONDARY:
.PHONY: all prog clean
.DEFAULT_GOAL := all
