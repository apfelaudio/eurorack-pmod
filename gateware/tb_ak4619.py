import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles


@cocotb.test()
async def test_i2c_write(dut):


    clock = Clock(dut.clk, 20, units='ns')
    cocotb.start_soon(clock.start())

    await RisingEdge(clock.signal)

    for i in range(100000):

        await RisingEdge(clock.signal)

        #dut._log.info(f"{hex(dut.cur_reg_counter.value)} - {hex(dut.cur_reg_value.value)}")
