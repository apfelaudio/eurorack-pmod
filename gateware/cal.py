#!/bin/python3

import serial
import os
import time
import numpy as np
import keyboard


def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

# [OUT OF DATE] Readings at output for -20k/+20k
# +20k: 5.950, broken, 6.034, 5.955
# -20k: -4.159, broken, -4.093, -4.152

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

ch_avg = np.zeros(4)
p5v_avg = np.zeros(4)
n5v_avg = np.zeros(4)

while True:
    ser.flushInput()
    raw = ser.read(100)
    raw = raw[raw.find(b'CH0'):]

    ix = 0
    ch_tc_values = np.zeros(4)
    while ix < len(raw):
        item = raw[ix:ix+5]
        if not item.startswith(b'CH') or ix > 15:
            break
        channel = int(item[2]) - ord('0')
        msb = item[3]
        lsb = item[4]
        value = (msb << 8) | lsb
        value_tc = twos_comp(value, 16)
        #print(channel, hex(value), value_tc, channel_to_cal(channel, value_tc))
        alpha = 0.1
        ch_avg[channel] = alpha*value_tc + (1-alpha)*ch_avg[channel]
        print(channel, hex(value), value_tc, int(ch_avg[channel]))
        ch_tc_values[channel] = value_tc
        ix = ix + 5

    if keyboard.is_pressed('p'):
        p5v_avg = np.copy(ch_avg)

    if keyboard.is_pressed('n'):
        n5v_avg = np.copy(ch_avg)

    print()
    print("+5v captured:", p5v_avg)
    print("-5v captured:", n5v_avg)

    shift_constant = -(n5v_avg+p5v_avg)/2.
    mp_constant = 2**10*40000*1./(n5v_avg-p5v_avg)
    print("shift_constant:", shift_constant)
    print("mp_constant:", mp_constant)

    print()
    cal_string = None
    if np.isfinite(shift_constant).all() and np.isfinite(mp_constant).all():
        cal_string = "@00000000 "
        for i in range(4):
            cal_string = cal_string + hex(int(shift_constant[i])).replace('0x','') + ' '
            cal_string = cal_string + hex(int(mp_constant[i])).replace('0x','') + ' '
        print(cal_string)

        print()
        print("Back-calculated channel values:")
        for i in range(4):
            back_calc = int(int(mp_constant[i])*(-ch_tc_values[i]-int(shift_constant[i]))) >> 10
            print(i, ch_tc_values[i], "->", back_calc, "(", back_calc/4000., "V )")
    else:
        cal_string = None
        print("Constants not finite, could not generate calibration string")
    print()

    if keyboard.is_pressed('x'):
        break

    time.sleep(0.1)

    os.system('clear')


