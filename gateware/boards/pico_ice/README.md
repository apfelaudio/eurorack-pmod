# Support for `pico-ice` from `tinyvision-ai-inc`

At the moment this uses the internal HFOSC at 12MHz so we don't depend on the RP2040 sending a clock signal to the FPGA.

Assuming the RP2040 is programmed with the DFU bootloader you can flash the binary over DFU with something like:

```
$ make BOARD=pico_ice
$ sudo dfu-util --alt 0 -D build/pico_ice/top.bin
```

I have removed the prog target for this board as there are a few different ways of flashing the FPGA depending on how the RP2040 is programmed.

I have not tried to mirror the UART through the RP2040 yet but it should be reasonable to do so by copying one of the pico-ice examples.
