#!/bin/python3

# I/O calibration utility for EURORACK-PMOD
#
# Calibration process:
# 1. Compile gateware and program FPGA with these defines in `top.sv`:
#    - OUTPUT_CALIBRATION
# 2. Connect +/- 5V source to all INPUTS
# 3. Run `sudo ./cal.py`
# 4. Supply 5V,  wait for values to settle, hold 'p' to capture
# 5. Supply -5V, wait for values to settle, hold 'n' to capture
# 6. At this point you can try other voltages to make sure the calibration is good
#    by looking at the 'back-calculated' values using the generated calibration.
# 7. Press 'o' to switch to OUTPUT calibration.
# 8. Loop back all outputs to inputs (1->1, 2->2, ...)
# 9. Wait for values to settle, hold 'p' to capture
# 10. Hold uButton, wait for values to settle, hold 'n' to capture
#    (the uButton switches between the output emitting uncalibrated +/- 5V signals)
# 11. The (calibrated) inputs are used to figure out the calibration constants for
#     the (uncalibrated) outputs.
# 12. Press 'x', copy the calibration string to the cal hex file.
# 13. Be careful to switch back off the `OUTPUT_CALIBRATION` define :)
#
# Note: if you check the output calibration with a multimeter, make sure
# to add a 100K load unless you calibrate with the CAL_OPEN_LOAD option below.

import serial
import sys
import os
import time
import numpy as np
import keyboard

if len(sys.argv) != 2:
    print("Usage: ./cal.py /dev/ttyX (serial port of FPGA board)")
    sys.exit(-1)

SERIAL_PORT = sys.argv[1]

# Input calibration is aiming for N counts per volt
COUNT_PER_VOLT = 4000

# Number of bits in multiply constant for input calibration
MP_N_BITS = 10

# Calibrate outputs such that they are correct if they are driving
# an open load (i.e a multimeter). Normally, the 1K output impedance
# should be driving a 100K input impedance causing a small droop.
# Set this to False for the latter case.
CAL_OPEN_LOAD = True

def twos_comp(val, bits):
    """compute the 2's complement of int value val"""
    if (val & (1 << (bits - 1))) != 0: # if sign bit is set e.g., 8bit: 128-255
        val = val - (1 << bits)        # compute negative value
    return val                         # return positive value as is

ser = serial.Serial(SERIAL_PORT, 1000000)

adc_avg = np.zeros(4)
p5v_adc_avg = np.zeros(4)
n5v_adc_avg = np.zeros(4)
p5v_dac_fb_avg = np.zeros(4)
n5v_dac_fb_avg = np.zeros(4)
adc_calibrated_avg = np.zeros(4)

input_cal = True

input_cal_string = None
output_cal_string = None

def decode_raw_samples(n, raw, array_avg):
    ix = 0
    ch_tc_values = np.zeros(n)
    while ix != n:
        channel = ix
        msb = raw[ix*2]
        lsb = raw[ix*2+1]
        value = (msb << 8) | lsb
        value_tc = twos_comp(value, 16)
        alpha = 0.3
        array_avg[channel] = alpha*value_tc + (1-alpha)*array_avg[channel]
        print(channel, hex(value), value_tc, int(array_avg[channel]))
        ch_tc_values[channel] = value_tc
        ix = ix + 1


while True:

    print("*** eurorack-pmod calibration / bringup tool ***")
    print()
    print("INPUT" if input_cal else "OUTPUT", "calibration")
    print("press 'o' to switch to OUTPUT once inputs are done")
    print()

    ser.flushInput()
    raw = ser.read(100)
    raw = raw[raw.find(b'\xbe\xef'):]
    values = {
        "magic1": raw[0],
        "magic2": raw[1],
        "eeprom_mfg": raw[2],
        "eeprom_dev": raw[3],
        "eeprom_serial": int.from_bytes(raw[4:8], "big"),
        "jack": raw[8],
    }
    [print(k, hex(v)) for k, v in values.items()]


    print("\nRaw ADC samples:")
    decode_raw_samples(4, raw[9:], adc_avg)

    if keyboard.is_pressed('o'):
        input_cal = False

    if keyboard.is_pressed('p'):
        if input_cal:
            p5v_adc_avg = np.copy(adc_avg)
        else:
            p5v_dac_fb_avg = np.copy(adc_calibrated_avg)

    if keyboard.is_pressed('n'):
        if input_cal:
            n5v_adc_avg = np.copy(adc_avg)
        else:
            n5v_dac_fb_avg = np.copy(adc_calibrated_avg)

    print()
    print("Step 1) INPUT CAL - inject calibration signal")
    print("Raw ADC [Inputs set to +5V]:", p5v_adc_avg)
    print("Raw ADC [Inputs set to -5V]:", n5v_adc_avg)
    print()
    print("Step 2) OUTPUT CAL - loop back all outputs to inputs")
    print("Raw ADC [DACs @ uncal +5V, loopback]:", p5v_dac_fb_avg)
    print("Raw ADC [DACs @ uncal -5V, loopback]:", n5v_dac_fb_avg)

    print()
    if input_cal_string is not None:
        print("Average raw ADC counts converted to voltages using current input calibration")
        cal_mem = [int(x, 16) for x in input_cal_string.strip().split(' ')[1:]]
        for channel in range(4):
            calibrated = ((-adc_avg[channel] - cal_mem[channel*2]) *
                         cal_mem[channel*2 + 1]) / (1 << MP_N_BITS)
            adc_calibrated_avg[channel] = calibrated
            print(f"in{channel}",round(calibrated / COUNT_PER_VOLT, ndigits=3), "V")


    shift_constant = None
    mp_constant = None

    if input_cal:
        shift_constant = -(n5v_adc_avg + p5v_adc_avg)/2.
        mp_constant = 2**MP_N_BITS * COUNT_PER_VOLT * 10./(n5v_adc_avg-p5v_adc_avg)
    else:
        range_constant = (p5v_dac_fb_avg - n5v_dac_fb_avg) / (COUNT_PER_VOLT * 10.)
        if CAL_OPEN_LOAD:
            # Tweak range constant to remove effect of 100K load impedance.
            # (in all cases it is assumed the device is connected in loopback
            # mode, all this does is tweak the constants emitted)
            range_constant = range_constant * (101./100.)
        mp_constant = 2**MP_N_BITS / range_constant
        shift_constant = (n5v_dac_fb_avg + p5v_dac_fb_avg)/2.
        shift_constant = shift_constant * range_constant

    print()
    print("CALIBRATION MEMORY ('x' to exit, copy this to 'cal_mem.hex')\n")
    cal_string = None
    if np.isfinite(shift_constant).all() and np.isfinite(mp_constant).all():
        cal_string = f"@0000000{'0' if input_cal else '8'} "
        for i in range(4):
            cal_string = cal_string + hex(int(shift_constant[i])).replace('0x','') + ' '
            cal_string = cal_string + hex(int(mp_constant[i])).replace('0x','') + ' '
    if input_cal:
        input_cal_string = cal_string
    else:
        output_cal_string = cal_string
    print("// Input calibration constants")
    print(input_cal_string)
    print("// Output calibration constants")
    print(output_cal_string)

    if keyboard.is_pressed('x'):
        break

    time.sleep(0.1)

    os.system('clear')
