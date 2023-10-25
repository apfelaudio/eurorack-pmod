#!/bin/python3

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


with open("touch-cfg.hex", "r") as f:
    xs = []
    ix = 0
    for line in f.readlines():
        raw = line.strip()
        v = int(raw, 16)
        if ix >= 2:
            print("reg", hex(ix-2), "hex", raw, "int", v)
        else:
            print("hex", raw, "int", v)
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
