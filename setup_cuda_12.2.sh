#!/bin/bash
# Install CUDA 12.2.2 locally (no root required)

set -e

CUDA_VERSION="12.2.2"
CUDA_INSTALLER_VERSION="535.104.05"
CUDA_INSTALLER="cuda_${CUDA_VERSION}_${CUDA_INSTALLER_VERSION}_linux.run"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/${CUDA_INSTALLER}"
INSTALL_DIR="${HOME}/.local/opt/cuda-12.2"

echo "CUDA 12.2.2 Installer"
echo "====================="
echo ""

# Check driver compatibility
if command -v nvidia-smi &> /dev/null; then
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
    CUDA_DRIVER_VERSION=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}')
    echo "NVIDIA driver: ${DRIVER_VERSION}"
    echo "Supports CUDA: ${CUDA_DRIVER_VERSION}"
    
    CUDA_MAJOR=$(echo $CUDA_DRIVER_VERSION | cut -d. -f1)
    CUDA_MINOR=$(echo $CUDA_DRIVER_VERSION | cut -d. -f2)
    
    if [ "$CUDA_MAJOR" -lt 12 ] || ([ "$CUDA_MAJOR" -eq 12 ] && [ "$CUDA_MINOR" -lt 2 ]); then
        echo ""
        echo "ERROR: Driver supports CUDA ${CUDA_DRIVER_VERSION}, need 12.2+"
        echo "Update your NVIDIA driver (requires 535.54.03 or newer)"
        exit 1
    fi
else
    echo "WARNING: nvidia-smi not found, cannot verify driver"
    echo "CUDA 12.2 requires NVIDIA driver 535.54.03+"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

echo ""
echo "Will install to: ${INSTALL_DIR}"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Download
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

if [ ! -f "${CUDA_INSTALLER}" ]; then
    echo ""
    echo "Downloading (~4GB)..."
    wget --show-progress "${CUDA_URL}"
fi

# Install
if [ ! -f "${INSTALL_DIR}/bin/nvcc" ]; then
    echo ""
    echo "Installing..."
    if ! sh "${CUDA_INSTALLER}" --silent --toolkit --toolkitpath="${INSTALL_DIR}" --no-drm --no-man-page --override 2>&1 | tee /tmp/cuda_install.log; then
        echo ""
        echo "ERROR: Installation failed. Check /tmp/cuda_install.log for details"
        tail -50 /tmp/cuda_install.log
        exit 1
    fi
fi

# Verify
if [ ! -f "${INSTALL_DIR}/bin/nvcc" ] || [ ! -f "${INSTALL_DIR}/include/cuda.h" ] || [ ! -f "${INSTALL_DIR}/lib64/libcublas.so.12" ]; then
    echo ""
    echo "ERROR: Installation incomplete"
    echo "Check that ${INSTALL_DIR} has bin/, include/, and lib64/ directories"
    ls -la "${INSTALL_DIR}" 2>/dev/null || true
    exit 1
fi

echo ""
echo "✓ CUDA 12.2.2 installed"
echo ""

# Configure shell
echo "Select shell:"
echo "  1) bash"
echo "  2) zsh"
read -p "Choice [1-2]: " -n 1 -r SHELL_CHOICE
echo ""

case $SHELL_CHOICE in
    1) SHELL_RC="${HOME}/.bashrc" ;;
    2) SHELL_RC="${HOME}/.zshrc" ;;
    *)
        echo ""
        echo "Manually add to your shell RC:"
        echo "  export PATH=\"\${HOME}/.local/opt/cuda-12.2/bin:\${PATH}\""
        echo "  export LD_LIBRARY_PATH=\"\${HOME}/.local/opt/cuda-12.2/lib64:\${LD_LIBRARY_PATH}\""
        exit 0
        ;;
esac

if grep -q "cuda-12.2" "${SHELL_RC}" 2>/dev/null; then
    echo "✓ Already configured in ${SHELL_RC}"
else
    cat >> "${SHELL_RC}" << 'EOF'

# CUDA 12.2.2
export PATH="${HOME}/.local/opt/cuda-12.2/bin:${PATH}"
export LD_LIBRARY_PATH="${HOME}/.local/opt/cuda-12.2/lib64:${LD_LIBRARY_PATH}"
EOF
    echo "✓ Added to ${SHELL_RC}"
fi

echo ""
echo "Done. Run: source ${SHELL_RC}"
echo ""
