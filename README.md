# Eurorack PMOD

**Assembled boards now available!** [get one **here :)**](https://lectronz.com/stores/apfelaudio)

**Eurorack PMOD** makes it easy for you to combine the world of FPGAs and [hardware electronic music synthesis](https://en.wikipedia.org/wiki/Eurorack). It is an expansion board for FPGA development boards that allows them to interface with a Eurorack hardware synthesizer. This board exposes 8 (4 in + 4 out) DC-coupled audio channels, 192KHz / 32bit sampling supported, at a -8V to +8V swing, amongst many more features. R3.1 hardware looks like this:

![assembled eurorack-pmod module R3.0 (panel)](docs/img/panel.jpg)
![assembled eurorack-pmod module R3.0 (top)](docs/img/pmod_top.jpg)


![ci workflow](https://github.com/schnommus/eurorack-pmod/actions/workflows/main.yml/badge.svg)


For a high-level overview on R2.2 hardware, **see [my FOSDEM '23 talk](https://youtu.be/Wbd-OfCWvKU)** on this project. Production hardware is named R3+ and has a few improvements (LEDs fully programmable, jack detection, calibration EEPROM).

[Want one?](#manufacturing). More photos can be found [below](#photos). 

### This project is:
- The design for a Eurorack-compatible PCB and front-panel, including a [PMOD](https://en.wikipedia.org/wiki/Pmod_Interface) connector (compatible with most FPGA dev boards). PCB designed in [KiCAD](https://www.kicad.org/). Design is [certified open hardware](https://certification.oshwa.org/de000135.html).
- Various [example cores](gateware/cores) (and calibration / driver cores for the audio CODEC) initially targeting an [iCEBreaker FPGA](https://1bitsquared.com/products/icebreaker) (iCE40 part) but many more boards are supported (see below). Examples include calibration, sampling, effects, synthesis sources and so on. The design files can be synthesized to a bitstream using Yosys' [oss-cad-suite](https://github.com/YosysHQ/oss-cad-suite-build).
- A [VCV Rack plugin](https://github.com/schnommus/verilog-vcvrack) so you can simulate your Verilog designs in a completely virtual modular system, no hardware required.

## Included examples
This repository contains a bunch of example DSP cores which are continuously being updated:
- Bitcrusher
- Filter (high pass / low pass / band pass)
- Clock divider
- .wav sampler
- Pitch shifter
- Sequential routing switch
- Echo/delay effect
- VCA (voltage controlled amplifier)
- VCO (voltage controlled oscillator)

These examples can all run out of the box on the development boards listed below.

## Choosing an FPGA development board
An FPGA development board itself is NOT included! Essentially anything iCE40 or ECP5 based that has a PMOD connector will support the open-source tools and the examples in this project. Just make sure you have enough LUTS, >3K is enough to do interesting things.

The following development boards have been tested with `eurorack-pmod` and are supported by the examples in the github repository
- iCEbreaker (iCE40 based)
- Colorlight i5 (ECP5 based)
- Colorlight i9 (ECP5 based)
- pico-ice from TinyVision (iCE40 based)

## Hardware details

![labelled eurorack-pmod 3.0](docs/img/labelled.jpg)

- 3HP module compatible with modular synthesizer systems.
    - Module depth is 47mm with both ribbon cables attached
    - This fits nicely in e.g. a 4MS POD 48X (pictured below).
- PMOD connector compatible with most FPGA development boards.
- 8 (4 in + 4 out) DC-coupled audio channels, 192KHz / 32bit sampling supported.
- PWM-controlled, user-programmable red/green LEDs on each output channel.
- Jack insertion detection on input & output jacks.
- Calibration EEPROM for unique ID and storing calibration data.
- I/O is about +/- 8V capable, wider is possible with a resistor change.

## Gateware details
- Examples based on iCE40 and ECP5 based FPGAs supported by open-source tools.
- User-defined DSP logic is decoupled from rest of system (see [`gateware/cores`](gateware/cores) directory)

## Getting Started

For now, I have tested builds on Linux and Windows (under MSYS2). Both are tested in CI.

0. Install the [OSS FPGA CAD flow](https://github.com/yosyshq/oss-cad-suite-build).
    - You may be able to get yosys / verilator from other package managers but I recommend using the [releases from YosysHQ](https://github.com/yosyshq/oss-cad-suite-build) so you're using the same binaries that CI is using.
    - On Linux, once the YosysHQ suite is installed and in PATH, you should be able to just use `make` in the gateware directory.
    - On Windows, CI is using MSYS2 with MINGW64 shell. Install MSYS2, MINGW64, extract the oss-cad-suite from YosysHQ and add it to PATH. Then you should be able to use `make` in the gateware directory.
    - Note: The gateware is automatically built and tested in CI, so for either platform it may be helpful to look at [`.github/workflows/main.yml`](.github/workflows/main.yml).

1. Build or obtain `eurorack-pmod` hardware and connect it to your FPGA development board using a ribbon cable or similar. (Double check that the pin mappings are correct, some ribbon cables will swap them on you! Default pinmaps are for the ribbon cables I shipped with hardware, you need to flip the pinmaps for a direct connection PMOD -> FPGA)
2. Try some of the examples. From the `gateware` directory, type `make` to see valid commands. By default if you do not select a CORE it will compile a bitstream with the 'mirror' core, which just sends inputs to outputs.
2. Calibrate your hardware using the process described in [`gateware/cal/cal.py`](gateware/cal/cal.py). Use this to create your own `gateware/cal/cal_mem.hex` to compensate for any DC biases in the ADCs/DACs. (this step is only necessary if you need sub-50mV accuracy on your inputs/outputs, which is the case if you are tuning oscillators, not so much if you are creating rhythm pulses.

# Project structure
The project is split into 2 directories, [`hardware`](hardware) for the PCB/panel and [`gateware`](gateware) for the FPGA source. Some interesting directories:
- [`gateware/cores`](gateware/cores): example user core implementations (i.e sequential switch, bitcrusher, filter, vco, vca, sampler etc).
- [`gateware/top.sv`](gateware/top.sv): top-level gateware with defines for selecting features.
- [`gateware/cal/cal.py`](gateware/cal/cal.py): tool used to calibrate the hardware after assembly, generating calibration memory.
- [`gateware/drivers`](gateware/drivers): driver for CODEC and I2C devices used on this board.
- [`hardware/eurorack-pmod-r3`](hardware/eurorack-pmod-r3): KiCAD design files for PCB and front panel.
- [`hardware/fab`](hardware/fab): gerber files and BOM for manufacturing the hardware.

# Manufacturing

**Assembled boards now available!** [get one **here :)**](https://lectronz.com/stores/apfelaudio)

Update: R3.1 (first production release) is fully functional with 1 rework, see github issues for up-to-date information.

Note: I gave some R3.0 (preproduction) units out at Hackaday Berlin '23. These are tested but NOT calibrated. They had 2 hacks applied. Some inductors are shorted with 0 ohm resistors as the wrong inductor was populated (means the board is a bit noiser than it should be - but still definitely useable). Also the reset line of the jack detect IO expander was routed incorrectly, so I manually shorted 2 pins of that chip. Functionally these boards are the same as R3.1, which fixes these issues.


## Known limitations
- Moved to github issues

# Photos

## Assembled `eurorack-pmod` (front)
![assembled eurorack-pmod module (front)](docs/img/leds_front.jpg)

## `eurorack-pmod` connected to iCEBreaker
![assembled eurorack-pmod module (in system)](docs/img/pmod_insystem.jpg)

# License

[![OSHW logo](docs/img/oshw.svg)](https://certification.oshwa.org/de000135.html)

Hardware and gateware are released under the CERN Open-Hardware License V2 `CERN-OHL-S`, mirrored in the LICENSE text in this repository.

If you wish to license parts of this design in a commercial product without a reciprocal open-source license, or you have a ground-breaking idea for a module we could work on together, feel free to contact me directly. See sebholzapfel.com.

*Copyright (C) 2022,2023 Sebastian Holzapfel*

The above LICENSE and copyright notice does NOT apply to imported artifacts in this repository (i.e datasheets, third-party footprints).
