#!/bin/python3

import serial
import os
import time


def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

# [OUT OF DATE] Readings at output for -5V/+5Vin
# 0: -4.588 -> 5.088
# 1: -4.587 -> 5.035
# 2: -4.564 -> 5.078
# 3: -4.597 -> 4.929

def channel_to_cal(ch, val):
    def cal2val(n5v, p5v, v):
        return ((-v) + (n5v+p5v)/2) / ((n5v-p5v) / 10.)
    out = 0
    if ch == 0:
        out = cal2val(14928, -23173, val)
    if ch == 1:
        out = cal2val(14644, -23393, val)
    if ch == 2:
        out = cal2val(14666, -23440, val)
    if ch == 3:
        out = cal2val(14565, -23475, val)
    return round(out, 4)

ser = serial.Serial('/dev/ttyUSB1', 115200)

while True:
    ser.flushInput()
    raw = ser.read(100)
    raw = raw[raw.find(b'CH0'):]

    ix = 0
    while ix < len(raw):
        item = raw[ix:ix+5]
        if not item.startswith(b'CH') or ix > 15:
            break
        channel = int(item[2]) - ord('0')
        msb = item[3]
        lsb = item[4]
        value = (msb << 8) | lsb
        value_tc = twos_comp(value, 16)
        print(channel, hex(value), value_tc, channel_to_cal(channel, value_tc))
        ix = ix + 5

    time.sleep(0.1)

    os.system('clear')
