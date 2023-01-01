import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

async def i2c_clock_in_byte(sda, scl):
    byte = 0x00
    for i in range(8):
        await RisingEdge(scl)
        byte |= sda.value << (8-i)
    await RisingEdge(scl)
    # Make sure we are releasing the ack bit
    assert sda.value == 1
    return byte >> 1

@cocotb.test()
async def test_i2cinit_00(dut):

    clock = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    await FallingEdge(dut.sda_out)

    # The first few bytes from a healthy 'ak4619-cfg.hex' (which are
    # unlikely to change and as such this kind of also acts as a sanity
    # check that the generated configuration is sane).
    test_bytes = [
            0x20, # Slave address and RW = 0
            0x00, # Start at register 0
            0x37, # 0x00 Power Management
            0xAC  # 0x01 Audio I/F Format
    ]

    for i in range(4):
        byte = await i2c_clock_in_byte(dut.sda_out, dut.scl)
        print(f"i2cinit clocked out {hex(byte)}")
        assert byte == test_bytes[i]
