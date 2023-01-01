#!/bin/bash
# Run all testbenches and combine the results.

for f in `find . -name Makefile`
do
    make -C `dirname $f`
done

./util/combine_results.py
