# ROCm 7.1 Dev Environment Template Blueprint

> Stored verbatim from provided specification for reference.

```
🧩 Project Specification — ROCm 7.1 Dev Environment Template
Overview
Create a GitHub template repository named
rocm7.1-devcontainer-template.
It provides:
A fully idempotent host setup script to install ROCm 7.1, AMD GPU drivers, Docker, and AMD Container Toolkit.
Multiple VS Code Dev Container configurations using official AMD ROCm 7.1 images.
Plain-text example Python scripts for verifying PyTorch, TensorFlow, and vLLM GPU access.
A GitHub Action to validate base image availability.
Clean separation between frameworks (Base Dev, PyTorch, TensorFlow, vLLM).

📁 Repository layout
rocm7.1-devcontainer-template/
├── README.md
├── scripts/
│   └── setup-host.sh
├── .devcontainer/
│   ├── base/devcontainer.json
│   ├── pytorch/devcontainer.json
│   ├── tensorflow/devcontainer.json
│   └── vllm/devcontainer.json
├── examples/
│   ├── pytorch-test.py
│   ├── tensorflow-test.py
│   └── vllm-test.py
└── .github/workflows/build.yml


🧠 1️⃣ Host setup — Idempotent script
File: scripts/setup-host.sh
#\!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Starting ROCm 7.1 Host Setup"

# 1. Check OS version
OS_CODENAME=$(lsb_release -cs)
if [[ "$OS_CODENAME" \!= "jammy" && "$OS_CODENAME" \!= "noble" ]]; then
  echo "[ERROR] Unsupported Ubuntu release: $OS_CODENAME"
  exit 1
fi

# 2. Install kernel headers/modules if missing
echo "[STEP] Installing kernel headers and extras"
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends \
     linux-headers-$(uname -r) \
     linux-modules-extra-$(uname -r)

# 3. Secure Boot warning
if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
  echo "[WARNING] Secure Boot is enabled. ROCm kernel modules may not load."
fi

# 4. Install AMDGPU installer if missing or outdated
ROCM_VER="7.1.0"
PKG_VER="7.1"
DEB_PKG="amdgpu-install_${PKG_VER/./_}-1_all.deb"

if \! dpkg -l | grep -q "amdgpu-install.*${ROCM_VER%.*}"; then
  echo "[STEP] Installing AMDGPU ROCm ${ROCM_VER}"
  wget -q https://repo.radeon.com/amdgpu-install/${PKG_VER}/ubuntu/jammy/${DEB_PKG} -O /tmp/${DEB_PKG}
  sudo apt-get install -y /tmp/${DEB_PKG}
  sudo amdgpu-install --usecase=dkms,rocm -y
else
  echo "[INFO] amdgpu-install ${ROCM_VER} already present"
fi

# 5. Add current user to video/render groups
echo "[STEP] Ensuring current user is in 'video' and 'render' groups"
sudo usermod -aG video,render $USER || true

# 6. Install Docker if missing
if \! command -v docker &>/dev/null; then
  echo "[STEP] Installing Docker CE"
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
  echo "[INFO] Docker already installed"
fi

# 7. Install AMD container toolkit if missing
if \! dpkg -l | grep -q amd-container-toolkit; then
  echo "[STEP] Installing AMD Container Toolkit"
  sudo apt-get install -y amd-container-toolkit
  sudo amd-ctk runtime configure --runtime=docker --set-as-default
  sudo systemctl restart docker
else
  echo "[INFO] AMD Container Toolkit already installed"
fi

# 8. Verify GPU access
echo "[STEP] Verifying ROCm GPU visibility"
if /opt/rocm/bin/rocminfo &>/dev/null; then
  echo "[SUCCESS] GPU detected via rocminfo"
else
  echo "[ERROR] GPU not visible — verify amdgpu modules"
  exit 1
fi

echo "[COMPLETE] ROCm 7.1 host setup finished."
echo "Please reboot if kernel modules were newly installed."

Characteristics
Fully idempotent and re-runnable.
Detects existing installs.
Logs progress clearly.
Validates GPU visibility.
Usage (for README)
sudo bash scripts/setup-host.sh


⚙️ 2️⃣ Dev Container configurations
All containers use official AMD ROCm 7.1 images, no mixed frameworks.
Shared runtime args
{
  "runArgs": [
    "--device=/dev/kfd",
    "--device=/dev/dri",
    "--group-add=video",
    "--ipc=host",
    "--shm-size=16g"
  ],
  "containerEnv": { "HIP_VISIBLE_DEVICES": "0" },
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python", "ms-toolsai.jupyter"]
    }
  }
}


a) .devcontainer/base/devcontainer.json
{
  "name": "ROCm 7.1 Base",
  "image": "rocm/dev-ubuntu-24.04:7.1-complete",
  "runArgs": [
    "--device=/dev/kfd",
    "--device=/dev/dri",
    "--group-add=video",
    "--ipc=host",
    "--shm-size=16g"
  ],
  "postCreateCommand": "sudo apt update && sudo apt install -y python3-pip && python3 -m pip install --upgrade pip"
}


b) .devcontainer/pytorch/devcontainer.json
{
  "name": "ROCm 7.1 PyTorch",
  "image": "rocm/pytorch:rocm7.1_ubuntu22.04_py3.10_pytorch_release_2.8.0",
  "runArgs": [
    "--device=/dev/kfd",
    "--device=/dev/dri",
    "--group-add=video",
    "--ipc=host",
    "--shm-size=16g"
  ],
  "postCreateCommand": "python3 - <<'EOF'\nimport torch; print('PyTorch ROCm available:', torch.cuda.is_available()); print('Device:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None')\nEOF"
}


c) .devcontainer/tensorflow/devcontainer.json
{
  "name": "ROCm 7.1 TensorFlow",
  "image": "rocm/tensorflow:rocm7.1-py3.12-tf2.20-dev",
  "runArgs": [
    "--device=/dev/kfd",
    "--device=/dev/dri",
    "--group-add=video",
    "--ipc=host",
    "--shm-size=16g"
  ],
  "postCreateCommand": "python3 - <<'EOF'\nimport tensorflow as tf; print(tf.config.list_physical_devices('GPU'))\nEOF"
}


d) .devcontainer/vllm/devcontainer.json
{
  "name": "ROCm 7.1 vLLM",
  "image": "rocm/vllm:rocm7.1_ubuntu22.04_py3.10_vllm_release_latest",
  "runArgs": [
    "--device=/dev/kfd",
    "--device=/dev/dri",
    "--group-add=video",
    "--ipc=host",
    "--shm-size=16g"
  ],
  "postCreateCommand": "python3 - <<'EOF'\nfrom vllm import LLM; print('vLLM initialized successfully')\nEOF"
}


🧪 3️⃣ Example validation scripts (plain text)
examples/pytorch-test.py
#\!/usr/bin/env python3
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

examples/tensorflow-test.py
#\!/usr/bin env python3
import tensorflow as tf

print("=== TensorFlow ROCm 7.1 Test ===")
print("TensorFlow version:", tf.__version__)
gpus = tf.config.list_physical_devices("GPU")
if gpus:
    print("Detected GPUs:", gpus)
else:
    print("No ROCm GPU visible. Check driver and container permissions.")

examples/vllm-test.py
#\!/usr/bin/env python3
from vllm import LLM

print("=== vLLM ROCm 7.1 Test ===")
try:
    llm = LLM(model="meta-llama/Llama-2-7b-chat-hf")
    print("vLLM initialized successfully.")
except Exception as e:
    print("vLLM failed to initialize:", e)


🔄 4️⃣ GitHub Actions CI
.github/workflows/build.yml
name: Verify ROCm DevContainer Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate AMD image availability
        run: |
          docker pull rocm/dev-ubuntu-24.04:7.1-complete
          docker pull rocm/pytorch:rocm7.1_ubuntu22.04_py3.10_pytorch_release_2.8.0
          docker pull rocm/tensorflow:rocm7.1-py3.12-tf2.20-dev
          docker pull rocm/vllm:rocm7.1_ubuntu22.04_py3.10_vllm_release_latest


📘 5️⃣ README.md (outline)
Title
ROCm 7.1 Dev Containers & Host Setup Template
Summary
Standardized, reproducible AMD ROCm 7.1 environments for GPU computing and AI frameworks (PyTorch, TensorFlow, vLLM).
Host setup
sudo bash scripts/setup-host.sh

Reboot after first run.
Using Dev Containers
code .devcontainer/pytorch
# or
code .devcontainer/tensorflow
# or
code .devcontainer/vllm

Then choose “Reopen in Container.”
Validation
python3 examples/pytorch-test.py
python3 examples/tensorflow-test.py
python3 examples/vllm-test.py

Notes
Do not mix frameworks in one container.
Ensure host and container use matching ROCm 7.1 versions.
If /dev/kfd missing, verify amdgpu modules and group membership.
Works on Ubuntu 22.04/24.04.

✅ 6️⃣ Idempotency Guarantees
Host script checks before every install.
Re-runnable with no side effects.
Containers use fixed image tags (7.1-*).
Example scripts are pure text and version-control friendly.

🧩 7️⃣ Uniqueness confirmation
A web search confirms:
No existing public GitHub template combining ROCm 7.1 host setup + Dev Containers.
No official AMD devcontainer template on containers.dev.
Publishing this project fills a real ecosystem gap and provides the first complete, developer-ready ROCm 7.1 template.
```
