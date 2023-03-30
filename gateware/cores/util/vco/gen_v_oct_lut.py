#!/bin/python3

# Generate a LUT (indexed by volts) mapped to the number of wavetable samples to
# increment by for every sample_clk. See vco.sv for more info.

def volts_to_freq(volts, a3_freq_hz=440.0):
    """Convert volts/oct (C3 == +3.0V) to frequency (Hz)."""
    return (a3_freq_hz / 8.0) * 2 ** (volts - 3.0/4.0)

def volts_to_delta(volts, wavetable_n_samples=256, sample_rate_hz=93750):
    """Index delta (fractional) for wavetable per sample clock)."""
    return (wavetable_n_samples / sample_rate_hz) * volts_to_freq(volts)

def print_line(volts, frac_bits_delta = 10):
    #volts = 3 + (midi_note - 60) / 12.0
    freq = volts_to_freq(volts)
    delta = volts_to_delta(volts)
    delta_fixed = delta * (1<<frac_bits_delta)
    #print(f"// {volts:.3f}V, {freq:.3f}Hz, delta_fixed={delta_fixed:.3f}")
    #print(f"{int(volts*4000)>>6}, {int(delta_fixed)}")
    print("{:04x}".format(int(delta_fixed)))

for i in range(0, 512):
    volts = i*64 / 4000
    print_line(volts)
