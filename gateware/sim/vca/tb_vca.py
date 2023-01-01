import cocotb
import random
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

def bit_not(n, numbits=16):
    return (1 << numbits) - 1 - n

def signed_to_twos_comp(n, numbits=16):
    return n if n >= 0 else bit_not(-n, numbits) + 1

def twos_comp_to_signed(n, numbits=16):
    if (1 << (numbits-1) & n) > 0:
        return -int(bit_not(n, numbits) + 1)
    else:
        return int(n)

@cocotb.test()
async def test_vca_00(dut):

    clock = Clock(dut.sample_clk, 5, units='us')
    cocotb.start_soon(clock.start())
    clock = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    ins  = [dut.sample_in0,  dut.sample_in1,  dut.sample_in2,  dut.sample_in3]
    outs = [dut.sample_out0, dut.sample_out1, dut.sample_out2, dut.sample_out3]

    for i in range(10):

        await RisingEdge(dut.sample_clk)

        data_in = []
        for inx in ins:
            random_sample = random.randint(-30000, 30000)
            data_in.append(random_sample)
            inx.value = signed_to_twos_comp(random_sample)

        await RisingEdge(dut.sample_clk)

        data_out = [twos_comp_to_signed(out.value) for out in outs]

        print(f"i={i} stimulus:", data_in)
        print(f"i={i} response:", data_out)

        assert data_out[0] == data_in[0]
        assert data_out[1] == (data_in[0] * data_in[1]) >> 16
        assert data_out[2] == data_in[2]
        assert data_out[3] == (data_in[2] * data_in[3]) >> 16
