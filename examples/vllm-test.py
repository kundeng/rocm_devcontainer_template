#!/usr/bin/env python3
from vllm import LLM

print("=== vLLM ROCm 7.1 Test ===")
try:
    llm = LLM(model="meta-llama/Llama-2-7b-chat-hf")
    print("vLLM initialized successfully.")
except Exception as e:
    print("vLLM failed to initialize:", e)
