#!/bin/python3

import matplotlib.pyplot as plt
import numpy as np

import math

N = 256

with open("wavetable.hex", "w") as f:
    all_values = []
    for i in range(N):
        # 3 sine waves and a sawtooth on top of each other.
        value = i/N
        if i > N/2:
            value -= 0.5
        if i > 3*N/4:
            value -= 0.1
        # Scale up to fit inside 16 bit integer and use 2s comp for negative.
        value = int((1<<14) * value)
        if value < 0:
            value = 0xffff + value
        all_values.append(value)
        line = "{:04x}\n".format(value)
        f.write(line)

    all_values = np.array(all_values, dtype=np.int16)
    plt.plot(all_values)
    plt.show()
