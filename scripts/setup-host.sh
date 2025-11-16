#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Starting ROCm 7.1 Host Setup"

# 1. Check OS version
OS_CODENAME=$(lsb_release -cs)
if [[ "$OS_CODENAME" != "jammy" && "$OS_CODENAME" != "noble" ]]; then
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

if ! dpkg -l | grep -q "amdgpu-install.*${ROCM_VER%.*}"; then
  echo "[STEP] Installing AMDGPU ROCm ${ROCM_VER}"
  wget -q https://repo.radeon.com/amdgpu-install/${PKG_VER}/ubuntu/jammy/${DEB_PKG} -O /tmp/${DEB_PKG}
  sudo apt-get install -y /tmp/${DEB_PKG}
  sudo amdgpu-install --usecase=dkms,rocm -y
else
  echo "[INFO] amdgpu-install ${ROCM_VER} already present"
fi

# 5. Add current user to video/render groups
echo "[STEP] Ensuring current user is in 'video' and 'render' groups'"
sudo usermod -aG video,render "$USER" || true

# 6. Install Docker if missing
if ! command -v docker &>/dev/null; then
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
if ! dpkg -l | grep -q amd-container-toolkit; then
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
