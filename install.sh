#!/bin/bash
CUDA_VERSION="cuda_9.1.85_387.26_linux"

function fail_msg() {
    echo $1
    exit 1
}

function download_cuda() {
    wget -nc "https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/$CUDA_VERSION"
}


if [ "$(id -u)" != "0" ]; then
    echo "Install script must be run as root user"
    echo "Usage: sudo $0"
    exit
fi

src/sysinfo.py > info.json

src/check_os_version info.json || fail_msg "Error while checking OS version"

src/check_nvidia_cards info.json || fail_msg "Error while checking for available GPU cards"

download_cuda || fail_msg "Error while downloading CUDA installer"

chmod +x $CUDA_VERSION
./$CUDA_VERSION

echo "TODO: locate CUDA, set PATH and LD_LIBRARY_PATH"

echo "TODO: download(?) and install CuDNN"

echo "TODO: Install virtualenv (NOTE: use easy_install for ubuntu 14.04 compat)"

echo "TODO: install tensorflow, keras, Python dependencies"

echo "TODO: install h5py (pip for 16.04, apt-get python-h5py for 14.04)"

echo "TODO: self-test and demo"
