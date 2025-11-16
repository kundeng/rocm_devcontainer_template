#!/usr/bin/env python3
import torch

print("=== PyTorch ROCm 7.1 Test ===")
print("Torch version:", torch.__version__)
print("HIP version:", getattr(torch.version, "hip", "N/A"))
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("Device count:", torch.cuda.device_count())
    print("Device 0:", torch.cuda.get_device_name(0))
else:
    print("No ROCm device detected. Check /dev/kfd mapping and group permissions.")
