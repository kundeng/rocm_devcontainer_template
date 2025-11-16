# ROCm 7.1 Dev Containers & Host Setup Template

Standardized, reproducible AMD ROCm 7.1 environments for GPU computing and AI frameworks (PyTorch, TensorFlow, vLLM).

## Host setup

```bash
sudo bash scripts/setup-host.sh
```

Reboot after the first run so kernel modules and group changes take effect.

## Using Dev Containers

From this repo:

```bash
code .devcontainer/pytorch
# or
code .devcontainer/tensorflow
# or
code .devcontainer/vllm
```

Then choose **"Reopen in Container"** in VS Code.

## Validation

Inside the appropriate container, run:

```bash
python3 examples/pytorch-test.py
python3 examples/tensorflow-test.py
python3 examples/vllm-test.py
```

## Notes

- Do not mix frameworks in one container.
- Ensure host and container use matching ROCm 7.1 versions.
- If `/dev/kfd` is missing, verify AMD GPU kernel modules and that the user is in `video` and `render` groups.
- Supported host OS: Ubuntu 22.04 (jammy) or 24.04 (noble).
