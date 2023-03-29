
all: $(PROJ).bin

%.json: %.sv $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log -p 'synth_ecp5 -top top -json $@' $< $(ADD_SRC)

%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log -p 'synth_ecp5 -top top -json $@' $< $(ADD_SRC)

%.config: $(PIN_DEF) %.json
	nextpnr-ecp5 --$(DEVICE) \
	$(if $(PACKAGE),--package $(PACKAGE)) \
	--speed 6 \
	--json $(filter-out $<,$^) \
	--lpf $< \
	--textcfg $@ \
	$(if $(PNR_SEED),--seed $(PNR_SEED))

%.bin: %.config
	ecppack --svf ${PROJ}.svf $< $@

%.svf: %.bin

clean:
	rm -rf $(PROJ).blif $(PROJ).config $(PROJ).bin $(PROJ).svf $(PROJ).json $(PROJ).log  $(ADD_CLEAN) $(PROJ).svf $(PROJ).config

.SECONDARY:
.PHONY: all prog clean
.DEFAULT_GOAL := all
