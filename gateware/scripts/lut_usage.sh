#!/bin/bash
# Shows LUT usage broken down by individual modules so you can see which parts are using resources.
find . -type f -name "*.sv" -o -name "*.v" | while read line ; do yosys -p "read -sv $line" -p "synth_ice40" | grep "Printing statistics" -A 20 ; done
