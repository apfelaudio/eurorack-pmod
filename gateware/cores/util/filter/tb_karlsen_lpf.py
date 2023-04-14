import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
from cocotb.result import TestFailure
import random

@cocotb.test()
async def karlsen_lpf_test(dut):
    # Initialize the inputs
    dut.rst.value = 1
    dut.clk.value = 0
    dut.sample_clk.value = 0
    dut.g.value = 0
    dut.resonance.value = 0
    dut.sample_in.value = 0

    # Start the clock
    clock_12m = Clock(dut.clk, 83.33, units='ns')
    cocotb.start_soon(clock_12m.start())
    clock_sample = Clock(dut.sample_clk, 83.33*128, units='ns')
    cocotb.start_soon(clock_sample.start())

    # Reset the filter
    dut.rst.value = 0
    await RisingEdge(dut.sample_clk)
    dut.rst.value = 1
    await RisingEdge(dut.sample_clk)
    dut.rst.value = 0
    await RisingEdge(dut.sample_clk)

    # Generate random input and parameters
    for i in range(300):
        sample_in_val = random.randint(-15000, 15000)
        g_val = 5000
        resonance_val = 30000

        dut.sample_in.value = sample_in_val
        dut.g.value = g_val
        dut.resonance.value = resonance_val

        # Wait for the next clock cycle
        await RisingEdge(dut.sample_clk)

        print(dut.sample_in.value)
        print(dut.sample_out.value)
