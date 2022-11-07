# Eurorack PMOD

Hardware and gateware for getting started in FPGA-based audio synthesis with open-source tools.

*insert photo*

## Hardware details
- 4HP module compatible with modular synthesizer systems.
- PMOD connector compatible with most FPGA development boards.
- 8 (4 in + 4 out) DC-coupled audio channels with analog LED indicators.
- CODEC supports 192KHz / 32bit samples on all channels.

## Gateware details
- Examples based on Icebreaker FPGA + open-source toolchain.
- User-defined DSP logic is decoupled from rest of system (example)
- Calibration process allows mV-level DC precision.

# Interesting directories
- `hardware/eurorack-pmod-pcb-flat`: KiCAD design files for PCB and front panel.
- `hardware/fab`: gerber files and BOM for manufacturing the hardware.
- `gateware/top.sv`: top-level gateware with defines for selecting features.
- `gateware/cores`: example core implementations (i.e clock divider, bitcrusher etc).
- `gateware/cal`: logic and scripts for calibration of the hardware after assembly.

# Project status / plans
The current revision (2.2) works fine without any bodges or modifications after assembly according to the supplied gerbers and BOM.

If there is enough interest in the project I would like to do a small manufacturing run (star this repository and let me know!).

## Known limitations
- Gateware only runs at 96KHz/16bit samples (no reason this can't be improved, just haven't gotten around to it).
- Selecting different DSP cores requires re-configuring the FPGA. It would be nice to have this runtime-selectable.
- The op-amps driving the LED indicators are running pretty close to their power limits. They don't get too hot but in a new revision perhaps a pass transistor would be a good idea.
- Adjacent ADC channels on the same bank (i.e Ch0/1 and Ch2/3) interfere with each other slightly at high DC offset levels. This seems to be an artifact of the CODEC itself (it is not designed to be DC-coupled, but performs the job quite well nontheless). This means that if you feed a constant voltage into e.g. Ch0 and a very slow 10Vpk-pk sine wave into Ch1 then you might see a few mV movement on Ch0's ADC values. This could probably be calibrated out with some effort. But for most applications it probably doesn't matter.

# License
Hardware and gateware are released under the CERN Open-Hardware License V2 `CERN-OHL-S`, mirrored in the LICENSE text in this repository.

If you wish to license parts of this design in a commercial product without a reciprocal open-source license, or you have a ground-breaking idea for a module we could work on together, feel free to contact me directly. See sebholzapfel.com.

*Copyright (C) 2022 Sebastian Holzapfel*

The above LICENSE and copyright notice does NOT apply to imported artifacts in this repository (i.e datasheets, third-party footprints).
