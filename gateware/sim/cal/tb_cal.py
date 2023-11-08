import sys
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

# Hack to import some helpers despite existing outside a package.
sys.path.append("..")
from util.i2s import *

@cocotb.test()
async def test_cal_00(dut):

    sample_width = 16

    clk_256fs = Clock(dut.clk_256fs, 83, units='ns')
    clk_fs = Clock(dut.clk_fs, 83*256, units='ns')
    cocotb.start_soon(clk_256fs.start())
    cocotb.start_soon(clk_fs.start(start_high=False))

    # Simulate all jacks connected so the cal core doesn't zero them
    dut.jack.value = Force(0xFF)

    clampl = -2**(sample_width-1) + 1
    clamph =  2**(sample_width-1) - 1;

    test_values = [
            23173,
            -14928,
            clamph,
            -clampl
    ]

    cal_mem = []
    with open("cal/cal_mem.hex", "r") as f_cal_mem:
        for line in f_cal_mem.readlines():
            if '//' in line:
                continue
            values = line.strip().split(' ')[1:]
            values = [int(x, 16) for x in values]
            cal_mem = cal_mem + values
    print(f"calibration constants: {cal_mem}")
    assert len(cal_mem) == 16


    channel = 0
    all_ins_outs = [(dut.in0, dut.out0),
                    (dut.in1, dut.out1),
                    (dut.in2, dut.out2),
                    (dut.in3, dut.out3),
                    (dut.in4, dut.out4),
                    (dut.in5, dut.out5),
                    (dut.in6, dut.out6),
                    (dut.in7, dut.out7)]
    for cal_inx, cal_outx in all_ins_outs:

        for value in test_values:
            expect = ((value - cal_mem[channel*2]) *
                      cal_mem[channel*2 + 1]) >> 10
            # Default all inputs to zero so we don't have undefined
            # values everywhere else in the input array.
            for i, o in all_ins_outs:
                i.value = Force(0)
            cal_inx.value = Force(bits_from_signed(value, sample_width))
            if expect >  clamph: expect = clamph
            if expect < clampl: expect = clampl
            print(f"ch={channel}\t{int(value):6d}\t", end="")
            await FallingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            await RisingEdge(dut.clk_fs)
            output = signed_from_bits(cal_outx.value, sample_width)
            print(f"=>\t{int(output):6d}\t(expect={expect})")
            cal_inx.value = Release()
            assert output == expect

        channel = channel + 1
