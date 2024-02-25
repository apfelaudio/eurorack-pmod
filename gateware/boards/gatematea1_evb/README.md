Olimex GateMateA1-EVB
---------------------

As of writing (board Rev. A) has a few oddities:
- The default dirtyJtag bootloader UART mirroring doesn't work, you have to recompile it and use the correct baud rate.
- The 2.5V <-> 3.3V level shifter connected to Pmod1 (U6 / TXB0108) does not support I2C, external hacks are needed!


Recompile dirtyJtag
-------------------

As of commit `938eb6d6` on upstream `https://github.com/phdussud/pico-dirtyJtag`, the only change required is to modify `cdc_uart.h` such that `USBUSART_BAUDRATE` is 1Mbaud (1000000), recompile and upload (hold RP-BOOT1 while powering up to expose a fake USB drive to drop the .uf2 file).
