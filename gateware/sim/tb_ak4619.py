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
    for i in range(16+1):
        await RisingEdge(dut.bick)
        word |= dut.sdin1.value << (16-i)
    for i in range(15):
        await RisingEdge(dut.bick)
    return word

def bit_not(n, numbits=16):
    return (1 << numbits) - 1 - n

def signed_to_twos_comp(n, numbits=16):
    return n if n >= 0 else bit_not(-n, numbits) + 1

def twos_comp_to_signed(n, numbits=16):
    if (1 << (numbits-1) & n) > 0:
        return -int(bit_not(n, numbits) + 1)
    else:
        return n

@cocotb.test()
async def test_adc_dac(dut):

    clock = Clock(dut.CLK, 83, units='ns')
    cocotb.start_soon(clock.start())

    TEST_L0 = 0xFC14
    TEST_R0 = 0xAD0F
    TEST_L1 = 0xDEAD
    TEST_R1 = 0xBEEF

    top = dut
    dut = dut.ak4619_instance
    dut.sdout1.value = 0


    await FallingEdge(dut.lrck)
    await clock_out_word(dut, TEST_L0)
    await clock_out_word(dut, TEST_R0)
    await clock_out_word(dut, TEST_L1)
    await clock_out_word(dut, TEST_R1)

    # Note: this edge is also where dac_words <= sample_in (sample.sv)

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

    await FallingEdge(dut.lrck)
    await FallingEdge(dut.lrck)

    result_l0 = await clock_in_word(dut)
    result_r0 = await clock_in_word(dut)
    result_l1 = await clock_in_word(dut)
    result_r1 = await clock_in_word(dut)

    print("Data clocked from sample_inX out to sdin1:")
    print(hex(result_l0), "(inverted: ", hex(bit_not(result_l0)), ")")
    print(hex(result_r0), "(inverted: ", hex(bit_not(result_r0)), ")")
    print(hex(result_l1), "(inverted: ", hex(bit_not(result_l1)), ")")
    print(hex(result_r1), "(inverted: ", hex(bit_not(result_r1)), ")")

    assert result_l0 == TEST_L0
    assert result_r0 == TEST_R0
    assert result_l1 == TEST_L1
    assert result_r1 == TEST_R1

    dut.sample_in0.value = Release()
    dut.sample_in1.value = Release()
    dut.sample_in2.value = Release()
    dut.sample_in3.value = Release()

    await FallingEdge(dut.lrck)

@cocotb.test()
async def test_cal(dut):

    clock = Clock(dut.cal_instance.sample_clk, 5, units='us')
    cocotb.start_soon(clock.start())
    clock = Clock(dut.cal_instance.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    test_values = [
            23173,
            -14928,
            32000,
            -32000
    ]

    cal_inst = dut.cal_instance

    cal_mem = []
    with open("cal_mem.hex", "r") as f_cal_mem:
        for line in f_cal_mem.readlines():
            values = line.strip().split(' ')[1:]
            values = [int(x, 16) for x in values]
            cal_mem = cal_mem + values
    print(f"calibration constants: {cal_mem}")
    assert len(cal_mem) == 16


    channel = 0
    for cal_inx, cal_outx in [(cal_inst.in0, cal_inst.out0),
                              (cal_inst.in1, cal_inst.out1),
                              (cal_inst.in2, cal_inst.out2),
                              (cal_inst.in3, cal_inst.out3),
                              (cal_inst.in4, cal_inst.out4),
                              (cal_inst.in5, cal_inst.out5),
                              (cal_inst.in6, cal_inst.out6),
                              (cal_inst.in7, cal_inst.out7)]:

        for value in test_values:
            expect = ((value - cal_mem[channel*2]) *
                      cal_mem[channel*2 + 1]) >> 10
            if expect > 28000: expect = 28000
            if expect < -28000: expect = -28000
            cal_inx.value = Force(signed_to_twos_comp(value))
            print(f"ch={channel}\t{int(value):6d}\t", end="")
            await RisingEdge(cal_inst.sample_clk)
            await RisingEdge(cal_inst.sample_clk)
            output = twos_comp_to_signed(cal_outx.value)
            print(f"=>\t{int(output):6d}\t(expect={expect})")
            cal_inx.value = Release()
            assert output == expect

        channel = channel + 1
