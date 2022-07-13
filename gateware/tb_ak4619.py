import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles


async def clock_out_word(dut, word):
    for i in range(16):
        await FallingEdge(dut.bick)
        dut.sdout1.value = (word >> (16-i)) & 1

async def clock_in_word(dut):
    word = 0x0000
    for i in range(16+1):
        await RisingEdge(dut.bick)
        word |= dut.sdin1.value << (16-i)
    return word


@cocotb.test()
async def test_adc_dac(dut):

    clock = Clock(dut.CLK, 20, units='ns')
    cocotb.start_soon(clock.start())

    TEST_L = 0xC0F0
    TEST_R = 0xAD0F

    top = dut
    dut = dut.ak4619_instance

    await FallingEdge(dut.lrck)

    await clock_out_word(dut, TEST_L)

    await RisingEdge(dut.lrck)

    await clock_out_word(dut, TEST_R)

    await RisingEdge(top.sample_clk)

    await FallingEdge(dut.lrck)

    result_l = await clock_in_word(dut)
    print(hex(result_l))
    assert result_l == TEST_L

    await RisingEdge(dut.lrck)

    result_r = await clock_in_word(dut)
    print(hex(result_r))
    assert result_r == TEST_R

    await FallingEdge(dut.lrck)
