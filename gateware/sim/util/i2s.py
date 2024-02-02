import math
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

async def i2s_clock_out_u32(bick, sdout, word):
    """Clock out a 32-bit word over I2S."""
    for i in range(32):
        await RisingEdge(bick)
        sdout.value = (word >> (0x1F-i)) & 1

async def i2s_clock_in_u32(bick, sdin):
    """Clock in a 32-bit word over I2S."""
    word = 0x00000000
    await RisingEdge(bick)
    for i in range(32):
        await FallingEdge(bick)
        word |= sdin.value << (0x1F-i)
    return word

def bits_not(n, width):
    """Bitwise NOT from positive integer of `width` bits."""
    n = int(n)
    return (1 << width) - 1 - n

def bits_from_signed(n, width):
    n = int(n)
    """Bits (2s complement) of `width` from signed integer."""
    return n if n >= 0 else bits_not(-n, width) + 1

def signed_from_bits(n, width):
    n = int(n)
    """Signed integer from (2s complement) bits of `width`."""
    if (1 << (width-1) & n) > 0:
        return -int(bits_not(n, width) + 1)
    else:
        return n
