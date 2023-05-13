import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.binary import BinaryValue

@cocotb.test()
async def apa102_controller_test(dut):
    # Command codes
    CMD_NONE = 0b00
    CMD_SOF = 0b01
    CMD_PIXEL = 0b10
    CMD_EOF = 0b11

    # Test parameters
    pixel_red = 0xAA
    pixel_green = 0xBB
    pixel_blue = 0xCC

    clock = Clock(dut.clk, 83, units='ns')
    cocotb.start_soon(clock.start())

    # set some sane defaults
    dut.reset.value = 1
    dut.pixel_red.value = 0
    dut.pixel_green.value = 0
    dut.pixel_blue.value = 0
    dut.cmd.value = CMD_NONE
    dut.strobe.value = 0

    print(dut.pixel_red.value)

    # Reset the module
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    async def send_sof():
        # Send start of frame
        dut.cmd.value = CMD_SOF
        dut.strobe.value = 1
        await RisingEdge(dut.clk)
        dut.strobe.value = 0
        await FallingEdge(dut.clk)

        # Wait until the module is not busy
        while dut.busy.value:
            await RisingEdge(dut.clk)

    async def send_pixel():
        # Send pixel data
        dut.cmd.value = CMD_PIXEL
        dut.pixel_red.value = pixel_red
        dut.pixel_green.value = pixel_green
        dut.pixel_blue.value = pixel_blue
        dut.strobe.value = 1
        await RisingEdge(dut.clk)
        dut.strobe.value = 0
        await FallingEdge(dut.clk)

        # Wait until the module is not busy
        while dut.busy.value:
            await RisingEdge(dut.clk)

    async def send_eof():
        # Send end of frame
        dut.cmd.value = CMD_EOF
        dut.strobe.value = 1
        await RisingEdge(dut.clk)
        dut.strobe.value = 0
        await FallingEdge(dut.clk)

        # Wait until the module is not busy
        while dut.busy.value:
            await RisingEdge(dut.clk)

    await send_sof()
    await send_pixel()
    await send_pixel()
    await send_eof()

    # And a few more clocks
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    await send_sof()
    await send_pixel()
    await send_pixel()
    await send_eof()

    # And a few more clocks
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
