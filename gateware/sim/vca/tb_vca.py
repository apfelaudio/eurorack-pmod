import sys
import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

# Hack to import some helpers despite existing outside a package.
sys.path.append("..")
from util.i2s import *

@cocotb.test()
async def test_vca_00(dut):

    sample_width=16

    clk_256fs = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clk_256fs.start())

    # Add 1/256 sample strobe
    dut.strobe.value = 0
    async def strobe():
        while True:
            dut.strobe.value = 1
            await ClockCycles(dut.clk, 1)
            dut.strobe.value = 0
            await ClockCycles(dut.clk, 255)
    cocotb.start_soon(strobe())

    ins  = [dut.sample_in0,  dut.sample_in1,  dut.sample_in2,  dut.sample_in3]
    outs = [dut.sample_out0, dut.sample_out1, dut.sample_out2, dut.sample_out3]

    for i in range(10):

        await RisingEdge(dut.strobe)

        data_in = []
        for inx in ins:
            random_sample = random.randint(-30000, 30000)
            data_in.append(random_sample)
            inx.value = bits_from_signed(random_sample, sample_width)

        await RisingEdge(dut.strobe)

        data_out = [signed_from_bits(out.value, sample_width) for out in outs]

        print(f"i={i} stimulus:", data_in)
        print(f"i={i} response:", data_out)

        assert data_out[0] == data_in[0]
        assert data_out[1] == (data_in[0] * data_in[1]) >> 16
        assert data_out[2] == data_in[2]
        assert data_out[3] == (data_in[2] * data_in[3]) >> 16
