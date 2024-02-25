DEFINES = "$(ADD_DEFINES) -DGATEMATE -D$(HW_REV)"

# Location of GateMate toolchain from colognechip.com (requires sign-up).
GM_TOOLCHAIN = /opt/cc-toolchain-linux

all: $(BUILD)/$(PROJ).cfg.bit

$(BUILD)/%-synth.v: %.sv $(ADD_SRC) $(ADD_DEPS)
	$(GM_TOOLCHAIN)/bin/yosys/yosys -f "verilog -sv $(DEFINES)" -ql $(BUILD)/$*.log -p 'synth_gatemate -top top -nomx8 -vlog $@' $< $(ADD_SRC)

%.cfg.bit: $(PIN_DEF) %-synth.v
	$(GM_TOOLCHAIN)/bin/p_r/p_r \
	-i $(filter-out $<,$^) \
	-o $@ \
	-ccf $(PIN_DEF) \
	-cCP

.SECONDARY:
.PHONY: all
.DEFAULT_GOAL := all
