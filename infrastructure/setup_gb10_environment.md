# GB10 Environment Setup Guide

This document describes how to prepare a fresh NVIDIA Grace Blackwell GB10 system
for running the Gracey-GB10 local inference node.

---

## 1. System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| OS        | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |
| Python    | 3.10    | 3.11+ |
| CUDA      | 12.4    | 12.6+ |
| RAM       | 128 GB unified | 128 GB unified |
| Storage   | 500 GB NVMe | 2 TB NVMe |

---

## 2. Driver and CUDA Installation

### 2.1 Install NVIDIA Drivers

```bash
# Add the NVIDIA driver PPA
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt update

# Install the latest recommended driver for GB10 (Blackwell architecture)
sudo apt install -y nvidia-driver-565 nvidia-utils-565

# Reboot to load the new driver
sudo reboot
```

After reboot, verify the driver is loaded:

```bash
nvidia-smi
```

You should see the GB10 listed with its full 128 GB unified memory.

### 2.2 Install CUDA Toolkit

```bash
# Download the CUDA 12.6 installer for Ubuntu 24.04 (match your architecture)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update
sudo apt install -y cuda-toolkit-12-6
```

Add CUDA to PATH:

```bash
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

Verify:

```bash
nvcc --version
```

### 2.3 Install cuDNN

```bash
sudo apt install -y libcudnn9-cuda-12
```

---

## 3. Python Environment

### 3.1 Install Python 3.11

```bash
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
```

### 3.2 Create a Virtual Environment

```bash
python3 -m venv ~/gracey-env
source ~/gracey-env/bin/activate
pip install --upgrade pip setuptools wheel
```

---

## 4. System Dependencies

```bash
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    htop \
    nvtop \
    screen \
    tmux \
    unzip \
    jq \
    libssl-dev \
    libffi-dev
```

---

## 5. Environment Variables

Add the following to `~/.bashrc` (or `/etc/environment` for system-wide):

```bash
# Gracey-GB10 Environment
export GRACEY_HOME=/opt/gracey
export GRACEY_MODELS_DIR=/opt/gracey/models
export GRACEY_LOGS_DIR=/var/log/gracey
export GRACEY_WORKERS=4

# CUDA / GPU settings
export CUDA_VISIBLE_DEVICES=0
export CUDA_DEVICE_MAX_CONNECTIONS=4

# GB10 unified memory tuning
export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

# OpenClaw
export OPENCLAW_CONFIG=/opt/gracey/openclaw/openclaw_config.yaml
export OPENCLAW_PORT=8080
```

Apply changes:

```bash
source ~/.bashrc
```

---

## 6. Directory Layout

```bash
sudo mkdir -p /opt/gracey/{models,logs,tmp}
sudo chown -R $USER:$USER /opt/gracey
sudo mkdir -p /var/log/gracey
sudo chown -R $USER:$USER /var/log/gracey
```

---

## 7. Post-Setup Verification

Run the following to confirm everything is operational:

```bash
nvidia-smi                          # GPU visible and memory reported
nvcc --version                      # CUDA compiler available
python3 -c "import torch; print(torch.cuda.is_available())"   # PyTorch GPU access
```

All three commands should succeed before proceeding to `openclaw_install.sh`.
