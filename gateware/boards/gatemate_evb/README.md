CologneChip CCGM1A1 Evaluation Board V3.2A
------------------------------------------

Support for this board currently has a few oddities and should be considered EXPERIMENTAL at the moment.

The following should be noted if you want to use `eurorack-pmod` with the CologneChip EVB:

- Make sure to update `GM_TOOLCHAIN` in `mk/gatemate.mk` to point to your CologneChip toolchain. As of the time of writing, a special nightly build is needed to build the bitstream reliably - but I assume this will be part of the official release in a few weeks.
- There is no spare pins on the built-in FTDI chip to use for UART, so you need to bring-your-own and connect RX to PMOD B pin 1 if you want to use the debug UART features.
- The PDN line is not pulled to 3V3 strongly enough by the level translators built into the EVB, which will cause the CODEC to stay offline. I worked around this by shorting PDN and 3V3 on the ribbon cable, doing so should have no adverse consequences.
- Touch scanning does not work - I am not sure why yet but I suspect it is just another artifact of the level translators as with PDN above.

Given the above, the following invocations seem to work (make sure to switch your board to JTAG mode):


```bash
make HW_REV=HW_R33 BOARD=gatemate_evb CORE=mirror
./openFPGALoader -b gatemate_evb_jtag build/gatemate_evb/top.cfg_00.cfg.bit
```
