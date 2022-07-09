import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles

ADDR_TEST_VALUE = 0x65
DATA_TEST_VALUE = 0xAB

N_REGS = 0x15

@cocotb.test()
async def test_i2c_write(dut):


    clock = Clock(dut.clk, 20, units='ns')
    cocotb.start_soon(clock.start())

    await RisingEdge(clock.signal)

    for i in range(300):

        await RisingEdge(clock.signal)

        #dut._log.info(f"{hex(dut.cur_reg_counter.value)} - {hex(dut.cur_reg_value.value)}")
