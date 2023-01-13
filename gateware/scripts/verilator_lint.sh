#!/bin/bash -e

verilator --lint-only -Ical -Iak4619 -Iutil -Icores top.sv
verilator --lint-only -Icores bitcrush.sv
verilator --lint-only -Icores clkdiv.sv
verilator --lint-only -Icores sampler.sv
verilator --lint-only -Icores seqswitch.sv
verilator --lint-only -Icores vca.sv
verilator --lint-only -Icores vco.sv
