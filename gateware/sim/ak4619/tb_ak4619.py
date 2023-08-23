import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release


async def clock_out_word(dut, word):
    for i in range(32):
        await RisingEdge(dut.bick)
        dut.sdout1.value = (word >> (0x1F-i)) & 1

async def clock_in_word(dut):
    word = 0x00000000
    for i in range(32):
        await FallingEdge(dut.bick)
        word |= dut.sdin1.value << (0x1F-i)
    return word

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
    await RisingEdge(dut.bick)
    await clock_out_word(dut, TEST_L0)
    await clock_out_word(dut, TEST_R0)
    await clock_out_word(dut, TEST_L1)
    await clock_out_word(dut, TEST_R1)

    # Note: this edge is also where dac_words <= sample_in (sample.sv)

    await FallingEdge(dut.lrck)
    print("Data clocked from sdout1 present at sample_outX:")
    print(hex(dut.sample_out0.value))
    print(hex(dut.sample_out1.value))
    print(hex(dut.sample_out2.value))
    print(hex(dut.sample_out3.value))

    assert dut.sample_out0.value == TEST_L0 >> 16
    assert dut.sample_out1.value == TEST_R0 >> 16
    assert dut.sample_out2.value == TEST_L1 >> 16
    assert dut.sample_out3.value == TEST_R1 >> 16

    dut.sample_in0.value = Force(TEST_L0 >> 16)
    dut.sample_in1.value = Force(TEST_R0 >> 16)
    dut.sample_in2.value = Force(TEST_L1 >> 16)
    dut.sample_in3.value = Force(TEST_R1 >> 16)

    await FallingEdge(dut.lrck)
    await FallingEdge(dut.bick)
    await FallingEdge(dut.bick)
    result_l0 = await clock_in_word(dut)
    result_r0 = await clock_in_word(dut)
    result_l1 = await clock_in_word(dut)
    result_r1 = await clock_in_word(dut)

    print("Data clocked from sample_inX out to sdin1:")
    print(hex(result_l0))
    print(hex(result_r0))
    print(hex(result_l1))
    print(hex(result_r1))

    assert result_l0 & 0xFFFFFF00 == TEST_L0
    assert result_r0 & 0xFFFFFF00 == TEST_R0
    assert result_l1 & 0xFFFFFF00 == TEST_L1
    assert result_r1 & 0xFFFFFF00 == TEST_R1

    dut.sample_in0.value = Release()
    dut.sample_in1.value = Release()
    dut.sample_in2.value = Release()
    dut.sample_in3.value = Release()

    await FallingEdge(dut.clk_fs)
