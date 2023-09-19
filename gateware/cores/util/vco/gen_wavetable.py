#!/bin/python3

import math

N = 256

with open("wavetable.hex", "w") as f:
    for i in range(N):
        # 3 sine waves and a sawtooth on top of each other.
        value = (1.0*math.sin(2*math.pi*i/N) +
                 0.5*math.sin(4*math.pi*i/N) +
                 0.3*math.sin(6*math.pi*i/N) +
                 (0.2*i/N - 0.5))/2)
        # Scale up to fit inside 16 bit integer and use 2s comp for negative.
        value = int((1<<14) * value)
        if value < 0:
            value = 0xffff + value
        line = "{:04x}\n".format(value)
        f.write(line)
