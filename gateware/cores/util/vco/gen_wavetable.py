#!/bin/python3

import math

import matplotlib.pyplot as plt

N = 256

values = []

with open("wavetable.hex", "w") as f:
    for i in range(N):
        # 3 sine waves and a sawtooth on top of each other.
        value = i/N - 0.5
        # Scale up to fit inside 16 bit integer and use 2s comp for negative.
        value = int((1<<14) * value)
        values.append(value)
        if value < 0:
            value = 0xffff + value
        line = "{:04x}\n".format(value)
        f.write(line)

plt.plot(values)
plt.show()
