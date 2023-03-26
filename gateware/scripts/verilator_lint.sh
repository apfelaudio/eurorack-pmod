#!/bin/bash -e

# Lint the entire design with calibration over UART enabled..
verilator --lint-only -DVERILATOR_LINT_ONLY -Ical -Idrivers -Iexternal \
    -DUART_SAMPLE_TRANSMITTER \
    -Iexternal/no2misc/rtl -Icores -Wno-INITIALDLY top.sv eurorack_pmod.sv

# Lint the entire design with output calibration enabled.
verilator --lint-only -DVERILATOR_LINT_ONLY -Ical -Idrivers -Iexternal \
    -DOUTPUT_CALIBRATION \
    -Iexternal/no2misc/rtl -Icores -Wno-INITIALDLY top.sv eurorack_pmod.sv

# Lint each core which can be selected
verilator --lint-only -Icores mirror.sv
verilator --lint-only -Icores bitcrush.sv
verilator --lint-only -Icores clkdiv.sv
verilator --lint-only -Icores sampler.sv
verilator --lint-only -Icores seqswitch.sv
verilator --lint-only -Icores vca.sv
verilator --lint-only -Icores vco.sv
verilator --lint-only -Icores pitch_shift.sv
verilator --lint-only -Icores stereo_echo.sv
