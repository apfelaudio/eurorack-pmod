import sys
import math
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

# Hack to import some helpers despite existing outside a package.
sys.path.append("..")
from util.i2s import *

@cocotb.test()
async def test_integration_00(dut):

    sample_width=16

    clk_256fs = Clock(dut.CLK, 83, units='ns')
    cocotb.start_soon(clk_256fs.start())

    dut.eurorack_pmod1.ak4619_instance.sdout1.value = 0
    # Simulate all jacks connected so the cal core doesn't zero them
    dut.eurorack_pmod1.jack.value = Force(0xFF)

    # The reset timer is downstream of the PLL lock.
    # So if we toggle the PLL lock, we are triggering
    # a reset from the highest-level part of the system.
    dut.sysmgr_instance.pll_lock.value = 0
    await RisingEdge(dut.clk_256fs)
    await RisingEdge(dut.clk_256fs)
    dut.sysmgr_instance.pll_lock.value = 1

    ak4619 = dut.eurorack_pmod1.ak4619_instance

    N = 20

    for i in range(N):

        v = bits_from_signed(int(16000*math.sin((2*math.pi*i)/N)), sample_width)

        await FallingEdge(ak4619.lrck)

        await i2s_clock_out_u32(ak4619.bick, ak4619.sdout1, v << 16)
        await i2s_clock_out_u32(ak4619.bick, ak4619.sdout1, v << 16)
        await i2s_clock_out_u32(ak4619.bick, ak4619.sdout1, v << 16)
        await i2s_clock_out_u32(ak4619.bick, ak4619.sdout1, v << 16)

        # Note: this edge is also where dac_words <= sample_in (sample.sv)

        print("Data clocked from sdout1 present at sample_outX:")
        print(hex(ak4619.sample_out0.value))
        print(hex(ak4619.sample_out1.value))
        print(hex(ak4619.sample_out2.value))
        print(hex(ak4619.sample_out3.value))
