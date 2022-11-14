#!/bin/python3

from scipy.io import wavfile
samplerate, data = wavfile.read('clap.wav')

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val & ((2 ** bits)-1)

print(samplerate)
print("sample range", max(data), min(data))
print(len(data), "samples")

for i in range(len(data)):
    if i == 0x1000:
        break
    if i % 8 == 0:
        print("@%08x" % (i), end='')
    v = twos_comp(data[i], 16)
    #msb = (v & 0xFF00) >> 8
    #lsb = v & 0x00FF
    print(" %02lX" % (v), end='')
    if i % 8 == 7:
        print()
