#!/bin/python3

import numpy as np
import matplotlib.pyplot as plt
from scipy.io import wavfile


# Initialize state variables
a1 = 0.0
a2 = 0.0
a3 = 0.0
a4 = 0.0
v = 0.0

def apply_filter(input_signal, fs, cutoff_freq, resonance):
    """
    Implements the Karlsen Fast Ladder III low-pass filter.

    https://www.musicdsp.org/en/latest/Filters/240-karlsen-fast-ladder.html

    Args:
        input_signal (ndarray): The input signal to filter.
        fs (int): The sample rate of the input signal, in Hz.
        cutoff_freq (float): The cutoff frequency of the filter, in Hz.
        resonance (float): The resonance of the filter, between 0 and 4.

    Returns:
        ndarray: The filtered signal.
    """
    global a1
    global a2
    global a3
    global a4
    global v

    # Calculate filter coefficients
    g = np.tan(np.pi * cutoff_freq / fs)


    # Initialize output array
    output_signal = np.zeros_like(input_signal)

    # Iterate over input samples
    for n in range(len(input_signal)):
        v = input_signal[n]

        # Resonance control
        rezz = a4 - v
        v = v - (rezz * resonance)

        """
        # Nonlinear saturation
        vnc = v
        if v > 1:
            v = 1
        elif v < -1:
            v = -1
        v = vnc + ((-vnc + v) * 0.9840)
        """

        # Four-pole low-pass filter
        a1 = a1 + ((-a1 + v) * g)
        a2 = a2 + ((-a2 + a1) * g)
        a3 = a3 + ((-a3 + a2) * g)
        a4 = a4 + ((-a4 + a3) * g)

        # Update output signal
        output_signal[n] = a4

    return output_signal

# Create a test signal (10 seconds of white noise)
fs = 44100
duration = 2
num_samples = int(fs * duration)
input_signal = np.random.randn(num_samples)

# Apply the filter
start_freq = 100 # Hz
end_freq = 5000 # Hz
resonance = 4

chunk_size = 1024

output_signal = np.zeros(num_samples)

# Process the input signal in chunks
for i in range(0, num_samples, chunk_size):
    chunk = input_signal[i:i+chunk_size]
    freq = start_freq + (end_freq - start_freq) * i / num_samples
    print(freq)
    filtered_chunk = apply_filter(chunk, fs, freq, resonance)
    output_signal[i:i+chunk_size] = filtered_chunk

"""
# Create a time vector
t = np.arange(num_samples) / fs

# Plot the input and output signals
plt.figure(figsize=(10, 4))
plt.plot(t, input_signal, label='Input')
plt.plot(t, output_signal, label='Output')
plt.xlabel('Time (s)')
plt.ylabel('Amplitude')
plt.title('Karlsen Fast Ladder III Filter')
plt.legend()
plt.show()
"""

# Save it
output_signal /= np.max(np.abs(output_signal))
wavfile.write("output.wav", fs, output_signal)
