from PIL import Image
import numpy as np

# ------------------------------
# CONFIGURATION
# ------------------------------

INPUT_IMAGE = "image.jpeg"
OUTPUT_PREVIEW = "image_64x64_preview.png"
OUTPUT_COE = "image.coe"

TARGET_W = 64
TARGET_H = 64

# ------------------------------
# LOAD ORIGINAL IMAGE
# ------------------------------
img = Image.open(INPUT_IMAGE).convert("L")   # grayscale

# ------------------------------
# SMART CENTER CROP
# ------------------------------
# crop to center square before resizing
w, h = img.size
min_dim = min(w, h)

left = (w - min_dim) // 2
top = (h - min_dim) // 2
right = left + min_dim
bottom = top + min_dim

img_cropped = img.crop((left, top, right, bottom))

# ------------------------------
# RESIZE CLEANLY (NEAREST preserves structure)
# ------------------------------
img_resized = img_cropped.resize((TARGET_W, TARGET_H), Image.NEAREST)

# ------------------------------
# SAVE PREVIEW (SEE WHAT FPGA WILL SEE)
# ------------------------------
img_resized.save(OUTPUT_PREVIEW)
print("Saved preview image as:", OUTPUT_PREVIEW)

# ------------------------------
# CONVERT TO PIXELS
# ------------------------------
pixels = np.array(img_resized, dtype=np.uint8).flatten()

# ------------------------------
# SAVE COE FILE
# ------------------------------
with open(OUTPUT_COE, "w") as f:
    f.write("memory_initialization_radix=10;\n")
    f.write("memory_initialization_vector=\n")

    for i, p in enumerate(pixels):
        if i == len(pixels)-1:
            f.write(f"{int(p)};")
        else:
            f.write(f"{int(p)},\n")

print("Generated COE file:", OUTPUT_COE)
print("Total pixels:", len(pixels))
