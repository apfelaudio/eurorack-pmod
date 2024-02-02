import sys
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

# Hack to import some helpers despite existing outside a package.
sys.path.append("..")
from util.i2s import *

@cocotb.test()
async def test_ak4619_00(dut):

    clk_256fs = Clock(dut.clk_256fs, 83, units='ns')
    clk_fs = Clock(dut.clk_fs, 83*256, units='ns')
    cocotb.start_soon(clk_256fs.start())
    cocotb.start_soon(clk_fs.start(start_high=False))

    TEST_L0 = 0xFC140000
    TEST_R0 = 0xAD0F0000
    TEST_L1 = 0xDEAD0000
    TEST_R1 = 0xBEEF0000

    dut.sdout1.value = 0

    dut.rst.value = 1
    await RisingEdge(dut.clk_256fs)
    await RisingEdge(dut.clk_256fs)
    dut.rst.value = 0

    await FallingEdge(dut.lrck)
    await i2s_clock_out_u32(dut.bick, dut.sdout1, TEST_L0)
    await i2s_clock_out_u32(dut.bick, dut.sdout1, TEST_R0)
    await i2s_clock_out_u32(dut.bick, dut.sdout1, TEST_L1)
    await i2s_clock_out_u32(dut.bick, dut.sdout1, TEST_R1)

    # Note: this edge is also where dac_words <= sample_in (sample.sv)

    await RisingEdge(dut.clk_fs)
    await FallingEdge(dut.clk_fs)
    print("Data clocked from sdout1 present at sample_outX:")
    print(hex(dut.sample_out0.value.integer))
    print(hex(dut.sample_out1.value.integer))
    print(hex(dut.sample_out2.value.integer))
    print(hex(dut.sample_out3.value.integer))

    assert dut.sample_out0.value == TEST_L0 >> 16
    assert dut.sample_out1.value == TEST_R0 >> 16
    assert dut.sample_out2.value == TEST_L1 >> 16
    assert dut.sample_out3.value == TEST_R1 >> 16

    dut.sample_in0.value = Force(TEST_L0 >> 16)
    dut.sample_in1.value = Force(TEST_R0 >> 16)
    dut.sample_in2.value = Force(TEST_L1 >> 16)
    dut.sample_in3.value = Force(TEST_R1 >> 16)

    await FallingEdge(dut.lrck)
    await FallingEdge(dut.lrck)

    result_l0 = await i2s_clock_in_u32(dut.bick, dut.sdin1)
    result_r0 = await i2s_clock_in_u32(dut.bick, dut.sdin1)
    result_l1 = await i2s_clock_in_u32(dut.bick, dut.sdin1)
    result_r1 = await i2s_clock_in_u32(dut.bick, dut.sdin1)

    print("Data clocked from sample_inX out to sdin1:")
    print(hex(result_l0))
    print(hex(result_r0))
    print(hex(result_l1))
    print(hex(result_r1))

    assert result_l0 == TEST_L0
    assert result_r0 == TEST_R0
    assert result_l1 == TEST_L1
    assert result_r1 == TEST_R1

    dut.sample_in0.value = Release()
    dut.sample_in1.value = Release()
    dut.sample_in2.value = Release()
    dut.sample_in3.value = Release()

    await FallingEdge(dut.clk_fs)
