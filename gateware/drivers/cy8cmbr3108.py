#!/bin/python3

"""
Touch IC utility -- verify the register indices and CRC in `cy8cmbr3108.hex`.
This was mostly just pulled out of Cypress' documentation. They have tools
to create the configuration dumps, however you aren't allowed to touch every
register which I needed to do for this use-case :)

If you run this utility from this directory, you'll get something like:

```
head 6e int 110
head 00 int 0
reg 0x0 hex 0xff int 255 SENSOR_EN
reg 0x1 hex 0x0 int 0
reg 0x2 hex 0x0 int 0 FSS_EN
reg 0x3 hex 0x0 int 0
...
reg 0x7d hex 0x0 int 0
reg 0x7e hex 0x86 int 134 CONFIG_CRC
reg 0x7f hex 0xc1 int 193
total bytes in file 130
bytes to crc 126
crc0 0x86
crc1 0xc1
CRC OK
```

If the CRC did not match (i.e you tweaked a register), you should copy the crc0 and crc1 (calculated CRC)
lines into the correct lines of the .hex file (CONFIG_CRC above). Then, if you re-run this tool it should
show CRC OK, which means the touch IC will accept your configuration.

"""

CY8CMBR3xxx_CONFIG_DATA_LENGTH = 126
CY8CMBR3xxx_CRC_BIT_WIDTH = 2 * 8
CY8CMBR3xxx_CRC_BIT4_MASK = 0x0F
CY8CMBR3xxx_CRC_BIT4_SHIFT = 4
CY8CMBR3xxx_CCITT16_DEFAULT_SEED = 0xffff
CY8CMBR3xxx_CCITT16_POLYNOM = 0x1021


def CY8CMBR3xxx_Calc4BitsCRC(value, remainder):
    # Divide the value by polynomial, via the CRC polynomial
    tableIndex = (value & CY8CMBR3xxx_CRC_BIT4_MASK) ^ (remainder >> (CY8CMBR3xxx_CRC_BIT_WIDTH - CY8CMBR3xxx_CRC_BIT4_SHIFT))
    remainder = (CY8CMBR3xxx_CCITT16_POLYNOM * tableIndex) ^ (remainder << CY8CMBR3xxx_CRC_BIT4_SHIFT)
    return remainder


def CY8CMBR3xxx_CalculateCrc(configuration):
    seed = CY8CMBR3xxx_CCITT16_DEFAULT_SEED

    # don't make count down cycle! CRC will be different!
    for byteValue in configuration:
        seed = CY8CMBR3xxx_Calc4BitsCRC(byteValue >> CY8CMBR3xxx_CRC_BIT4_SHIFT, seed) & 0xffff
        seed = CY8CMBR3xxx_Calc4BitsCRC(byteValue, seed) & 0xffff

    return seed

# From the datasheet for this chip, offsets of each register.
REG_MAP = """SENSOR_EN 0x00
FSS_EN 0x02
TOGGLE_EN 0x04
LED_ON_EN 0x06
SENSITIVITY0 0x08
SENSITIVITY1 0x09
SENSITIVITY2 0x0a
SENSITIVITY3 0x0b
BASE_THRESHOLD0 0x0c
BASE_THRESHOLD1 0x0d
FINGER_THRESHOLD2 0x0e
FINGER_THRESHOLD3 0x0f
FINGER_THRESHOLD4 0x10
FINGER_THRESHOLD5 0x11
FINGER_THRESHOLD6 0x12
FINGER_THRESHOLD7 0x13
FINGER_THRESHOLD8 0x14
FINGER_THRESHOLD9 0x15
FINGER_THRESHOLD10 0x16
FINGER_THRESHOLD11 0x17
FINGER_THRESHOLD12 0x18
FINGER_THRESHOLD13 0x19
FINGER_THRESHOLD14 0x1a
FINGER_THRESHOLD15 0x1b
SENSOR_DEBOUNCE 0x1c
BUTTON_HYS 0x1d
BUTTON_LBR 0x1f
BUTTON_NNT 0x20
BUTTON_NT 0x21
PROX_EN 0x26
PROX_CFG 0x27
PROX_CFG2 0x28
PROX_TOUCH_TH0 0x2a
PROX_TOUCH_TH1 0x2c
PROX_RESOLUTION0 0x2e
PROX_RESOLUTION1 0x2f
PROX_HYS 0x30
PROX_LBR 0x32
PROX_NNT 0x33
PROX_NT 0x34
PROX_POSITIVE_TH0 0x35
PROX_POSITIVE_TH1 0x36
PROX_NEGATIVE_TH0 0x39
PROX_NEGATIVE_TH1 0x3a
LED_ON_TIME 0x3d
BUZZER_CFG 0x3e
BUZZER_ON_TIME 0x3f
GPO_CFG 0x40
PWM_DUTYCYCLE_CFG0 0x41
PWM_DUTYCYCLE_CFG1 0x42
PWM_DUTYCYCLE_CFG2 0x43
PWM_DUTYCYCLE_CFG3 0x44
PWM_DUTYCYCLE_CFG4 0x45
PWM_DUTYCYCLE_CFG5 0x46
PWM_DUTYCYCLE_CFG6 0x47
PWM_DUTYCYCLE_CFG7 0x48
SPO_CFG 0x4c
DEVICE_CFG0 0x4d
DEVICE_CFG1 0x4e
DEVICE_CFG2 0x4f
DEVICE_CFG3 0x50
I2C_ADDR 0x51
REFRESH_CTRL 0x52
STATE_TIMEOUT 0x55
SLIDER_CFG 0x5d
SLIDER1_CFG 0x61
SLIDER1_RESOLUTION 0x62
SLIDER1_THRESHOLD 0x63
SLIDER2_CFG 0x67
SLIDER2_RESOLUTION 0x68
SLIDER2_THRESHOLD 0x69
SLIDER_LBR 0x71
SLIDER_NNT 0x72
SLIDER_NT 0x73
SCRATCHPAD0 0x7a
SCRATCHPAD1 0x7b
CONFIG_CRC 0x7e"""

REG_DICT = {}

for line in REG_MAP.split("\n"):
    name, addr = line.split(" ")
    REG_DICT[int(addr.strip(), 16)] = name.strip()

with open("cy8cmbr3108-cfg.hex", "r") as f:
    xs = []
    ix = 0
    for line in f.readlines():
        raw = line.strip()
        v = int(raw, 16)
        if ix >= 2:
            reg_ix = ix-2
            name = ""
            if reg_ix in REG_DICT:
                name = REG_DICT[reg_ix]
            print("reg", hex(reg_ix), "hex", hex(int(raw, 16)), "int", v, name)
        else:
            print("head", raw, "int", v)
        xs.append(v)
        ix += 1
    print("total bytes in file", len(xs))
    xs_crc = xs[2:-2]
    print("bytes to crc", len(xs_crc))
    crc = CY8CMBR3xxx_CalculateCrc(xs_crc)
    print("crc0", hex(crc & 0x00FF))
    print("crc1", hex((crc & 0xFF00)>>8))
    if xs[-2] == crc & 0x00FF and xs[-1] == ((crc & 0xFF00) >> 8):
        print("CRC OK")
    else:
        print("CRC NOT OK")
