# Eurorack PMOD

A bridge between the FPGA world and Eurorack.

This project contains hardware and gateware for getting started in FPGA-based audio synthesis with open source tools.

![assembled eurorack-pmod module (front)](docs/img/eurorack-pmod.jpg)

More photos can be found [below](#photos).

## Hardware details
- 4HP module compatible with modular synthesizer systems.
- PMOD connector compatible with most FPGA development boards.
- 8 (4 in + 4 out) DC-coupled audio channels with analog LED indicators.
- CODEC supports 192KHz / 32bit samples on all channels.
- I/O clamps at +/- 6.5V max, wider is possible with a resistor change.

## Gateware details
- Examples based on Icebreaker FPGA + open-source toolchain.
- User-defined DSP logic is decoupled from rest of system (see [`gateware/cores`](gateware/cores) directory)
- Calibration process allows mV-level DC precision.

## Gateware architecture
![gateware architecture](docs/img/gateware-arch.png)

Links to the most important modules depicted above are provided below.

# Project structure
The project is split into 2 directories, [`hardware`](hardware) for the PCB/panel and [`gateware`](gateware) for the FPGA source. Some interesting directories:
- [`hardware/eurorack-pmod-pcb-flat`](hardware/eurorack-pmod-pcb-flat): KiCAD design files for PCB and front panel.
- [`hardware/fab`](hardware/fab): gerber files and BOM for manufacturing the hardware.
- [`gateware/cal/cal.py`](gateware/cal/cal.py): tool used to calibrate the hardware after assembly, generating calibration memory.
- [`gateware/top.sv`](gateware/top.sv): top-level gateware with defines for selecting features.
- [`gateware/ak4619`](gateware/ak4619): driver for AK4619 ADC/DAC used on this board.
- [`gateware/cores`](gateware/cores): example user core implementations (i.e clock divider, sampler, bitcrusher etc).

# Manufacturing
The current revision (2.2) works fine without any bodges or modifications after assembly according to the supplied gerbers and BOM.

**Want a board?** Please fill out this [google form](https://forms.gle/rSEGuKGHPVXYotHRA). If there are enough people interested I may do a small manufacturing run.

## Known limitations
- Gateware only runs at 96KHz/16bit samples (no reason this can't be improved, just haven't gotten around to it).
- Selecting different DSP cores requires re-configuring the FPGA. It would be nice to have this runtime-selectable.
- The op-amps driving the LED indicators are running pretty close to their power limits. They don't get too hot but in a new revision perhaps a pass transistor would be a good idea.
- Adjacent ADC channels on the same bank (i.e Ch0/1 and Ch2/3) interfere with each other slightly at high DC offset levels. This seems to be an artifact of the CODEC itself (it is not designed to be DC-coupled, but performs the job quite well nontheless). This means that if you feed a constant voltage into e.g. Ch0 and a very slow 10Vpk-pk sine wave into Ch1 then you might see a few mV movement on Ch0's ADC values. This could probably be calibrated out with some effort. But for most applications it probably doesn't matter.

# Photos

## Assembled `eurorack-pmod` (front)
![assembled eurorack-pmod module (front)](docs/img/eurorack-pmod.jpg)

## Assembled `eurorack-pmod` (top)
![assembled eurorack-pmod module (top)](docs/img/eurorack-pmod-top.jpg)

## `eurorack-pmod` In system (with LEDs on)
![assembled eurorack-pmod module (in system)](docs/img/eurorack-pmod-system.jpg)

# License
Hardware and gateware are released under the CERN Open-Hardware License V2 `CERN-OHL-S`, mirrored in the LICENSE text in this repository.

If you wish to license parts of this design in a commercial product without a reciprocal open-source license, or you have a ground-breaking idea for a module we could work on together, feel free to contact me directly. See sebholzapfel.com.

*Copyright (C) 2022 Sebastian Holzapfel*

The above LICENSE and copyright notice does NOT apply to imported artifacts in this repository (i.e datasheets, third-party footprints).
