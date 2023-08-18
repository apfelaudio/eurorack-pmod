import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release


async def clock_out_word(dut, word):
    for i in range(16):
        await FallingEdge(dut.bick)
        dut.sdout1.value = (word >> (0xF-i)) & 1
    for i in range(16):
        await FallingEdge(dut.bick)
        dut.sdout1.value = 0

async def clock_in_word(dut):
    word = 0x0000
    for i in range(16):
        await RisingEdge(dut.bick)
        word |= dut.sdin1.value << (15-i)
    for i in range(16):
        await RisingEdge(dut.bick)
    return word

@cocotb.test()
async def test_ak4619_00(dut):

    clk_256fs = Clock(dut.clk_256fs, 83, units='ns')
    clk_fs = Clock(dut.clk_fs, 83*256, units='ns')
    cocotb.start_soon(clk_256fs.start())
    cocotb.start_soon(clk_fs.start(start_high=False))

    TEST_L0 = 0xFC14
    TEST_R0 = 0xAD0F
    TEST_L1 = 0xDEAD
    TEST_R1 = 0xBEEF

    dut.sdout1.value = 0

    await FallingEdge(dut.clk_fs)
    await clock_out_word(dut, TEST_L0)
    await clock_out_word(dut, TEST_R0)
    await clock_out_word(dut, TEST_L1)
    await clock_out_word(dut, TEST_R1)

    # Note: this edge is also where dac_words <= sample_in (sample.sv)

    await RisingEdge(dut.clk_fs)
    await FallingEdge(dut.clk_fs)
    print("Data clocked from sdout1 present at sample_outX:")
    print(hex(dut.sample_out0.value))
    print(hex(dut.sample_out1.value))
    print(hex(dut.sample_out2.value))
    print(hex(dut.sample_out3.value))

    assert dut.sample_out0.value == TEST_L0
    assert dut.sample_out1.value == TEST_R0
    assert dut.sample_out2.value == TEST_L1
    assert dut.sample_out3.value == TEST_R1

    dut.sample_in0.value = Force(TEST_L0)
    dut.sample_in1.value = Force(TEST_R0)
    dut.sample_in2.value = Force(TEST_L1)
    dut.sample_in3.value = Force(TEST_R1)

    await FallingEdge(dut.clk_fs)
    await FallingEdge(dut.clk_fs)

    result_l0 = await clock_in_word(dut)
    result_r0 = await clock_in_word(dut)
    result_l1 = await clock_in_word(dut)
    result_r1 = await clock_in_word(dut)

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
