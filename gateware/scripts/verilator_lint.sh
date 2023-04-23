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
verilator --lint-only cores/mirror.sv
verilator --lint-only cores/bitcrush.sv
verilator --lint-only cores/clkdiv.sv
verilator --lint-only cores/sampler.sv
verilator --lint-only cores/seqswitch.sv
verilator --lint-only cores/vca.sv
verilator --lint-only -Icores/util cores/pitch_shift.sv
verilator --lint-only -Icores/util cores/stereo_echo.sv
verilator --lint-only -Icores/util/filter cores/filter.sv
verilator --lint-only -Icores/util/vco -Icores/util/filter cores/vco.sv
verilator --lint-only cores/util/filter/karlsen_lpf.sv
verilator --lint-only cores/util/filter/karlsen_lpf_pipelined.sv
verilator --lint-only cores/util/vco/wavetable_vco.sv
verilator --lint-only -Icores/util dc_block.sv
