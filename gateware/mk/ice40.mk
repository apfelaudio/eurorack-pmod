DEFINES = "$(ADD_DEFINES) -DICE40 -DHW_REV=$(HW_REV)"

all: $(BUILD)/$(PROJ).bin

$(BUILD)/%.json: %.sv $(ADD_SRC) $(ADD_DEPS)
	yosys -f "verilog -sv $(DEFINES)" -ql $(BUILD)/$*.log -p 'synth_ice40 -dsp -top top -json $@' $< $(ADD_SRC)

$(BUILD)/%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -f "verilog $(DEFINES)" -ql $(BUILD)/$*.log -p 'synth_ice40 -dsp -top top -json $@' $< $(ADD_SRC)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) \
	$(if $(PACKAGE),--package $(PACKAGE)) \
	--json $(filter-out $<,$^) \
	--pcf $< \
	--asc $@ \
	$(if $(PNR_SEED),--seed $(PNR_SEED))

%.bin: %.asc
	icepack $< $@

.SECONDARY:
.PHONY: all prog
.DEFAULT_GOAL := all
