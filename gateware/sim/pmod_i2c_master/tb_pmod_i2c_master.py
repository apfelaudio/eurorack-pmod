import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge, RisingEdge, ClockCycles
from cocotb.handle import Force, Release

async def i2c_clock_in_byte(sda, scl, invert):
    byte = 0x00
    for i in range(8):
        await (FallingEdge(scl) if invert else RisingEdge(scl))
        sda_val = sda.value
        if invert:
            sda_val = 0 if sda_val else 1
        byte |= sda_val << (8-i)
    await (FallingEdge(scl) if invert else RisingEdge(scl))
    return byte >> 1

@cocotb.test()
async def test_i2cinit_00(dut):

    clock = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    dut.rst.value = 1

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    dut.rst.value = 0

    dut.i2c_state.value = 5 # Jump to I2C_INIT_CODEC1

    await RisingEdge(dut.sda_oe)

    # The first few bytes from a healthy 'ak4619-cfg.hex' (which are
    # unlikely to change and as such this kind of also acts as a sanity
    # check that the generated configuration is sane).
    test_bytes = [
            0x20, # Slave address and RW = 0
            0x00, # Start at register 0
            0x37, # 0x00 Power Management
            0xAE  # 0x01 Audio I/F Format
    ]

    bytes_out = []
    for i in range(4):
        byte = await i2c_clock_in_byte(dut.sda_oe, dut.scl_oe, invert=True)
        print(f"i2cinit clocked out {hex(byte)}")
        bytes_out.append(byte)

    for i in range(4):
        assert bytes_out[i] == test_bytes[i]
