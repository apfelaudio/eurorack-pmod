#!/bin/bash -e

# Lint an entire ICE40 design.
verilator --lint-only -DVERILATOR_LINT_ONLY \
    -DICE40 \
    -DSELECTED_DSP_CORE=mirror \
    -Iboards/icebreaker \
    -Ical \
    -Idrivers \
    -Iexternal \
    -Iexternal/no2misc/rtl \
    -Icores \
    -Icores/util \
    -Wno-INITIALDLY \
    top.sv

# Lint an entire ECP5 design.
verilator --lint-only -DVERILATOR_LINT_ONLY \
    -DECP5 \
    -DSELECTED_DSP_CORE=mirror \
    -Iboards/colorlight_i5 \
    -Ical \
    -Idrivers \
    -Iexternal \
    -Iexternal/no2misc/rtl \
    -Icores \
    -Icores/util \
    -Wno-INITIALDLY \
    top.sv

# Lint each core which can be selected
verilator --lint-only -Icores mirror.sv
verilator --lint-only -Icores bitcrush.sv
verilator --lint-only -Icores clkdiv.sv
verilator --lint-only -Icores sampler.sv
verilator --lint-only -Icores seqswitch.sv
verilator --lint-only -Icores vca.sv
verilator --lint-only -Icores vco.sv
verilator --lint-only cores/util/filter/karlsen_lpf.sv
verilator --lint-only cores/util/filter/karlsen_lpf_pipelined.sv
verilator --lint-only -Icores -Icores/util/filter filter.sv
verilator --lint-only -Icores -Icores/util pitch_shift.sv
verilator --lint-only -Icores -Icores/util stereo_echo.sv
verilator --lint-only -Icores -Icores/util dc_block.sv
