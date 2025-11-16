#!/usr/bin/env python3
import tensorflow as tf

print("=== TensorFlow ROCm 7.1 Test ===")
print("TensorFlow version:", tf.__version__)
gpus = tf.config.list_physical_devices("GPU")
if gpus:
    print("Detected GPUs:", gpus)
else:
    print("No ROCm GPU visible. Check driver and container permissions.")
