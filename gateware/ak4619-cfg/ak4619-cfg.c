#include <stdio.h>
#include <stdint.h>


#define I2C_N_BYTES 0x17

const uint8_t reg_default_values[I2C_N_BYTES] = {
    0x20, // I2C slave address and RW bit (W=0).
    0x00, // Register address to start at.

    0x17, // 0x00 Power Management
    0x0C, // 0x01 Audio I/F Format
    0x0C, // 0x02 Audio I/F Format
    0x00, // 0x03 System Clock Setting
    0x22, // 0x04 MIC AMP Gain
    0x22, // 0x05 MIC AMP Gain
    0x30, // 0x06 ADC1 Lch Digital Volume
    0x30, // 0x07 ADC1 Rch Digital Volume
    0x30, // 0x08 ADC2 Lch Digital Volume
    0x30, // 0x09 ADC2 Rch Digital Volume
    0x00, // 0x0A ADC Digital Filter Setting
    0x55, // 0x0B ADC Analog Input Setting
    0x00, // 0x0C Reserved
    0x06, // 0x0D ADC Mute & HPF Control
    0x18, // 0x0E DAC1 Lch Digital Volume
    0x18, // 0x0F DAC1 Rch Digital Volume
    0x18, // 0x10 DAC2 Lch Digital Volume
    0x18, // 0x11 DAC2 Rch Digital Volume
    0x04, // 0x12 DAC Input Select Setting
    0x05, // 0x13 DAC De-Emphasis Setting
    0x0A, // 0x14 DAC Mute & Filter Setting
};

int main(int argc, char **argv)
{
	fprintf(stderr, "Generating register dump.\n");

	for (int i = 0; i != I2C_N_BYTES; i++) {
		if ((i % 8) == 0) {
			printf("@%08x", i);
		}
		printf(" %02lX", reg_default_values[i]);
		if ((i % 8) == 7) {
			printf("\n");
		}
	}

	fprintf(stderr, "\ndone\n");

	return 0;
}
