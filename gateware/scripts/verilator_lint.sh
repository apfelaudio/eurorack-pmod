#!/bin/bash -e

verilator --lint-only -Ical -Idrivers -Iexternal/no2misc/rtl -Icores -Wno-INITIALDLY top.sv
verilator --lint-only -Icores bitcrush.sv
verilator --lint-only -Icores clkdiv.sv
verilator --lint-only -Icores sampler.sv
verilator --lint-only -Icores seqswitch.sv
verilator --lint-only -Icores vca.sv
verilator --lint-only -Icores vco.sv
verilator --lint-only -Icores pitch_shift.sv
verilator --lint-only -Icores stereo_echo.sv
