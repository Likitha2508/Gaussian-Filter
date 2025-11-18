import serial
import time
import numpy as np
from PIL import Image
import matplotlib.pyplot as plt
import re
from scipy.signal import convolve2d

# -----------------------------
# UART PARAMETERS
# -----------------------------
PORT = 'COM6'
BAUD = 115200

WIDTH = 64
HEIGHT = 64
PIXELS = WIDTH * HEIGHT
BYTES_EXPECTED = PIXELS * 2    # 8192 bytes

print(f"Opening serial port {PORT}...")
ser = serial.Serial(PORT, BAUD, timeout=0.2)
time.sleep(0.3)

print(f"Waiting for {BYTES_EXPECTED} bytes from FPGA...\n")

buffer = bytearray()
start_time = time.time()
last_update = time.time()
TIMEOUT = 20

# -----------------------------
# RECEIVE DATA 
# -----------------------------
while len(buffer) < BYTES_EXPECTED and (time.time() - start_time) < TIMEOUT:
    data = ser.read(256)
    if data:
        buffer.extend(data)

    if time.time() - last_update > 0.5:
        print(f"Received {len(buffer)}/{BYTES_EXPECTED} bytes...", end="\r")
        last_update = time.time()

ser.close()
print("\n")

# -----------------------------
# Timeout check
# -----------------------------
if len(buffer) < BYTES_EXPECTED:
    print(f"Timeout! Received only {len(buffer)} bytes.")
else:
    print("Successfully received all 8192 bytes!")

with open("image.coe") as f:
    txt = f.read()

nums = re.findall(r"\d+", txt.split("memory_initialization_vector=")[1])
data = np.array(list(map(int, nums)), dtype=np.uint8)

img = data.reshape((64, 64))

# Gaussian kernel
kernel = np.array([
    [1, 2, 1],
    [2, 4, 2],
    [1, 2, 1]
], dtype=np.float32) / 16.0

# Apply Gaussian filter
gaussian_img = convolve2d(img, kernel, mode='same', boundary='symm')
gaussian_img = gaussian_img.astype(np.uint8)

# =====================================================================
# SAVE & DISPLAY ONLY THE GAUSSIAN IMAGE
# =====================================================================
Image.fromarray(gaussian_img, mode='L').save("gaussian_output.png")
print("Saved gaussian_output.png")

plt.figure()
plt.imshow(gaussian_img, cmap='gray')
plt.title("Gaussian Output")
plt.colorbar()
plt.show()
