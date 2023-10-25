import math
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release


async def clock_out_word(dut, word):
    await FallingEdge(dut.bick)
    for i in range(32):
        await RisingEdge(dut.bick)
        dut.sdout1.value = (word >> (0x1F-i)) & 1

async def clock_in_word(dut):
    word = 0x00000000
    await RisingEdge(dut.bick)
    for i in range(32):
        await FallingEdge(dut.bick)
        word |= dut.sdin1.value << (0x1F-i)
    return word

def bit_not(n, numbits=16):
    return (1 << numbits) - 1 - n

def signed_to_twos_comp(n, numbits=16):
    return n if n >= 0 else bit_not(-n, numbits) + 1

@cocotb.test()
async def test_integration_00(dut):

    clk_256fs = Clock(dut.CLK, 83, units='ns')
    cocotb.start_soon(clk_256fs.start())

    dut.eurorack_pmod1.ak4619_instance.sdout1.value = 0

    dut.sysmgr_instance.pll_lock.value = 0
    await RisingEdge(dut.clk_256fs)
    await RisingEdge(dut.clk_256fs)
    dut.sysmgr_instance.pll_lock.value = 1

    dut = dut.eurorack_pmod1.ak4619_instance

    N = 2000

    await FallingEdge(dut.lrck)

    for i in range(N):

        v = signed_to_twos_comp(int(
            2000*math.sin((2*math.pi*i)/(N/10)) +
            2000*math.sin((2*math.pi*i)/(N/23))
            ))

        await clock_out_word(dut, v << 16)
        await clock_out_word(dut, v << 16)
        await clock_out_word(dut, v << 16)
        await clock_out_word(dut, v << 16)

        # Note: this edge is also where dac_words <= sample_in (sample.sv)

        print("Data clocked from sdout1 present at sample_outX:")
        print(hex(dut.sample_out0.value))
        print(hex(dut.sample_out1.value))
        print(hex(dut.sample_out2.value))
        print(hex(dut.sample_out3.value))
