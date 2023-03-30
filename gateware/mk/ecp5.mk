DEFINES = "$(ADD_DEFINES) -DECP5"

all: $(BUILD)/$(PROJ).bin

$(BUILD)/%.json: %.sv $(ADD_SRC) $(ADD_DEPS)
	yosys -f "verilog -sv $(DEFINES)" -ql $(BUILD)/$*.log -p 'synth_ecp5 -top top -json $@' $< $(ADD_SRC)

$(BUILD)/%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -f "verilog $(DEFINES)" -ql $(BUILD)/$*.log -p 'synth_ecp5 -top top -json $@' $< $(ADD_SRC)

%.config: $(PIN_DEF) %.json
	nextpnr-ecp5 --$(DEVICE) \
	$(if $(PACKAGE),--package $(PACKAGE)) \
	--speed 6 \
	--json $(filter-out $<,$^) \
	--lpf $< \
	--textcfg $@ \
	$(if $(PNR_SEED),--seed $(PNR_SEED))

%.bin: %.config
	ecppack $< $@

.SECONDARY:
.PHONY: all prog
.DEFAULT_GOAL := all
