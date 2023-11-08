#!/bin/python3

"""
I/O calibration utility for EURORACK-PMOD

Calibration process:
1. Compile gateware and program FPGA with these defines in `top.sv`:
   - OUTPUT_CALIBRATION
2. Connect +/- 5V source to all INPUTS
3. Run `sudo ./cal.py`
4. Supply 5V,  wait for values to settle, hold 'p' to capture
5. Supply -5V, wait for values to settle, hold 'n' to capture
6. At this point you can try other voltages to make sure the calibration is good
   by looking at the 'back-calculated' values using the generated calibration.
7. Press 'o' to switch to OUTPUT calibration.
8. Loop back all outputs to inputs (1->1, 2->2, ...)
9. Wait for values to settle, hold 'p' to capture
10. Hold uButton, wait for values to settle, hold 'n' to capture
   (the uButton switches between the output emitting uncalibrated +/- 5V signals)
11. The (calibrated) inputs are used to figure out the calibration constants for
    the (uncalibrated) outputs.
12. Press 'x', copy the calibration string to the cal hex file.
13. Be careful to switch back off the `OUTPUT_CALIBRATION` define :)

Note: if you check the output calibration with a multimeter, make sure
to add a 100K load unless you calibrate with the CAL_OPEN_LOAD option below.
"""

import argparse
import serial
import sys
import os
import time
import numpy as np
import keyboard
from dataclasses import dataclass, field, fields, MISSING

@dataclass
class CalibrationArguments:
    """Command-line arguments for eurorack-pmod calibration."""
    serial_port: str = field(
            default="",
            metadata={'help': 'Serial port to use for calibration e.g., /dev/ttyUSBX'})
    serial_baud: int = field(
            default=1000000,
            metadata={'help': 'Baud rate for serial communication set in top.sv // debug_uart instance.'})
    n_channels: int = field(
            default=4,
            metadata={'help': 'Total number of input channels.'})
    wbits: int = field(
            default=16,
            metadata={'help': 'Bits per sample actually being used in the design (top.sv).'})
    uart_wbits: int = field(
            default=32,
            metadata={'help': 'Maximum bits per sample in sample stream from debug_uart.sv.'})
    cal_open_load: bool = field(
            default=True,
            metadata={'help': 'Calibrate outputs for an open load. Set to False if driving a 100K input impedance.'})
    count_per_volt: int = field(
            default=4000,
            metadata={'help': 'Input calibration is aiming for N counts per volt.'})
    mp_n_bits: int = field(
            default=10,
            metadata={'help': 'Number of bits in multiply constant for input calibration.'})

class TwosComplement:

    @staticmethod
    def _bits_not(n, width):
        """Bitwise NOT from positive integer of `width` bits."""
        return (1 << width) - 1 - n

    @staticmethod
    def from_signed(n, width):
        """Bits (2s complement) of `width` from signed integer."""
        return n if n >= 0 else TwosComplement._bits_not(-n, width) + 1

    @staticmethod
    def to_signed(n, width):
        """Signed integer from (2s complement) bits of `width`."""
        if (1 << (width - 1) & n) > 0:
            return -int(TwosComplement._bits_not(n, width) + 1)
        else:
            return n

class CalibrationTool:
    def __init__(self, args):
        self.args = args
        self.ser = serial.Serial(args.serial_port, args.serial_baud)
        self.adc_avg = np.zeros(4)
        self.p5v_adc_avg = np.zeros(4)
        self.n5v_adc_avg = np.zeros(4)
        self.p5v_dac_fb_avg = np.zeros(4)
        self.n5v_dac_fb_avg = np.zeros(4)
        self.adc_calibrated_avg = np.zeros(4)
        self.input_cal = True
        self.input_cal_string = None
        self.output_cal_string = None

        assert self.args.wbits % 8 == 0
        assert self.args.uart_wbits % 8 == 0

    def run_calibration(self):
        while True:
            self._clear_screen()
            self._print_header()
            raw = self._flush_and_read_serial()
            values = {
                "magic1": raw[0],
                "magic2": raw[1],
                "eeprom_mfg": raw[2],
                "eeprom_dev": raw[3],
                "eeprom_serial": int.from_bytes(raw[4:8], "big"),
                "jack": raw[8],
            }
            [print(k, hex(v)) for k, v in values.items()]
            self._decode_raw_samples(raw[9:])
            self._handle_user_input()
            self._calculate_calibration_strings()
            time.sleep(0.1)

    def _clear_screen(self):
        os.system('clear')

    def _print_header(self):
        print("*** eurorack-pmod calibration / bringup tool ***")
        print()
        print("INPUT" if self.input_cal else "OUTPUT", "calibration")
        print("press 'o' to switch to OUTPUT once inputs are done")
        print()

    def _flush_and_read_serial(self):
        """Flush serial input and read values."""
        self.ser.flushInput()
        raw = self.ser.read(100)
        return raw[raw.find(b'\xbe\xef'):]

    def _decode_raw_samples(self, raw):
        """Decode raw samples and average them."""
        print("\nRaw ADC samples:")
        # Low-pass smoothing constant
        alpha = 0.3
        for ix in range(self.args.n_channels):
            bytes_start_index = ix * 4
            value = int.from_bytes(raw[bytes_start_index:bytes_start_index + 4], 'big')
            value_tc = TwosComplement.to_signed(value, self.args.uart_wbits)
            # Update smoothed averages
            self.adc_avg[ix] = alpha * value_tc + (1 - alpha) * self.adc_avg[ix]
            print(ix, hex(value), value_tc, int(self.adc_avg[ix]))

    def _handle_user_input(self):
        """Handle keyboard input to adjust calibration settings."""
        if keyboard.is_pressed('o'):
            self.input_cal = False

        if keyboard.is_pressed('p'):
            if self.input_cal:
                self.p5v_adc_avg = np.copy(self.adc_avg)
            else:
                self.p5v_dac_fb_avg = np.copy(self.adc_calibrated_avg)

        if keyboard.is_pressed('n'):
            if self.input_cal:
                self.n5v_adc_avg = np.copy(self.adc_avg)
            else:
                self.n5v_dac_fb_avg = np.copy(self.adc_calibrated_avg)

        if keyboard.is_pressed('x'):
            sys.exit(0)  # Exit the program

    def _calculate_calibration_strings(self):
        print()
        print("Step 1) INPUT CAL - inject calibration signal")
        print("Raw ADC [Inputs set to +5V]:", self.p5v_adc_avg)
        print("Raw ADC [Inputs set to -5V]:", self.n5v_adc_avg)
        print()
        print("Step 2) OUTPUT CAL - loop back all outputs to inputs")
        print("Raw ADC [DACs @ uncal +5V, loopback]:", self.p5v_dac_fb_avg)
        print("Raw ADC [DACs @ uncal -5V, loopback]:", self.n5v_dac_fb_avg)

        print()
        if self.input_cal_string is not None:
            print("Average raw ADC counts converted to voltages using current input calibration")
            cal_mem = [int(x, 16) for x in self.input_cal_string.strip().split(' ')[1:]]
            for channel in range(self.args.n_channels):
                calibrated = ((-self.adc_avg[channel] - TwosComplement.to_signed(cal_mem[channel*2], self.args.wbits)) *
                             TwosComplement.to_signed(cal_mem[channel*2 + 1], self.args.wbits)) / (1 << self.args.mp_n_bits)
                self.adc_calibrated_avg[channel] = calibrated
                print(f"in{channel}",round(calibrated / self.args.count_per_volt, ndigits=3), "V")


        shift_constant = None
        mp_constant = None

        if self.input_cal:
            shift_constant = -(self.n5v_adc_avg + self.p5v_adc_avg)/2.
            mp_constant = 2**self.args.mp_n_bits * self.args.count_per_volt * 10./(self.n5v_adc_avg-self.p5v_adc_avg)
        else:
            range_constant = (self.p5v_dac_fb_avg - self.n5v_dac_fb_avg) / (self.args.count_per_volt * 10.)
            if self.args.cal_open_load:
                # Tweak range constant to remove effect of 100K load impedance.
                # (in all cases it is assumed the device is connected in loopback
                # mode, all this does is tweak the args emitted)
                range_constant = range_constant * (101./100.)
            mp_constant = 2**self.args.mp_n_bits / range_constant
            shift_constant = (self.n5v_dac_fb_avg + self.p5v_dac_fb_avg)/2.
            shift_constant = shift_constant * range_constant

        def conv(constant):
            return hex(TwosComplement.from_signed(int(constant), self.args.wbits)).replace('0x','')

        print()
        print("CALIBRATION MEMORY ('x' to exit, copy this to 'cal_mem.hex')\n")
        cal_string = None
        if np.isfinite(shift_constant).all() and np.isfinite(mp_constant).all():
            cal_string = f"@0000000{0 if self.input_cal else int(self.args.n_channels*(self.args.wbits/8)):x} "
            for i in range(4):
                cal_string = cal_string + conv(shift_constant[i]) + ' '
                cal_string = cal_string + conv(mp_constant[i]) + ' '
        if self.input_cal:
            self.input_cal_string = cal_string
        else:
            self.output_cal_string = cal_string
        print("// Input calibration constants")
        print(self.input_cal_string)
        print("// Output calibration constants")
        print(self.output_cal_string)


def parse_args_with_defaults(defaults):
    parser = argparse.ArgumentParser(description='Calibration tool arguments.')
    # Use the default values from the dataclass for the command line arguments
    for field in fields(defaults):
        parser.add_argument(
            f'--{field.name.replace("_", "-")}',
            type=type(getattr(defaults, field.name)),
            default=getattr(defaults, field.name),
            help=field.metadata.get("help", "")
        )
    return parser.parse_args()

if __name__ == "__main__":
    args = CalibrationArguments()
    args = parse_args_with_defaults(args)
    if args.serial_port == "":
        print("Nominal usage: ./cal.py --serial-port /dev/ttyUSBX")
        sys.exit(0)  # Exit the program
    calibration_tool = CalibrationTool(args)
    calibration_tool.run_calibration()
