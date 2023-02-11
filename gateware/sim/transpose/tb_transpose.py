import pickle
import cocotb
import random
import math
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
async def test_transpose_00(dut):

    clock = Clock(dut.sample_clk, 5, units='us')
    cocotb.start_soon(clock.start())
    clock = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    dut.sample_in0.value = 0

    for i in range(1024):
        await RisingEdge(dut.sample_clk)

    ins = []
    out0 = []
    out1 = []
    outs = []

    data_out_last = None

    breaknext = False

    for i in range(4096):
        await RisingEdge(dut.sample_clk)

        data_in = int(1000*math.sin(i / 100))
        dut.sample_in0.value = signed_to_twos_comp(data_in)

        #out0.append(twos_comp_to_signed(dut.sample_out0.value))
        #out1.append(twos_comp_to_signed(dut.sample_out1.value))
        data_out = twos_comp_to_signed(dut.sample_out0.value)

        print(f"i={i} in:", data_in)
        print(f"i={i} out:", data_out)
        #print(f"i={i} delay0:", out0[-1])
        #print(f"i={i} delay1:", out1[-1])

        ins.append(data_in)
        outs.append(data_out)

        if data_out_last is not None:
            print(f"del0: {int(dut.delay_out0)}")
            print(f"env0: {int(dut.env0)}")
            print(f"del1: {int(dut.delay_out1)}")
            print(f"env1: {int(dut.env1)}")
            if breaknext:
                break
            if abs(data_out - data_out_last) > 50:
                print("=========================")
                breaknext = True

        data_out_last = data_out

    """
    with open("dump.pkl", "wb") as f:
        pickle.dump({"i": ins, "o0": out0, "o1": out1, "o2": out2})
        """
