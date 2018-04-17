#!/bin/bash
# Works for Ubuntu Server 16.04 and CUDA 9.0

CUDA_VERSION="cuda_9.0.176_384.81_linux-run"
CUDA_URL="https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_384.81_linux-run"

CUDNN_URL="http://downloads.deeplearninggroup.com/cudnn-9.0-linux-x64-v7.tgz"
CUDNN_SHA256="1a3e076447d5b9860c73d9bebe7087ffcb7b0c8814fd1e506096435a2ad9ab0e"

function install_bare_requirements() {
    apt install -y python python3 gcc make virtualenv python-dev python3-dev python-h5py
}

function install_openai_requirements() {
    apt install -y cmake zlib1g-dev ffmpeg
}

function fail_msg() {
    echo -e "[31m$*[39m"
    exit 1
}

function download_cuda() {
    wget -nc $CUDA_URL
}

function green() {
    echo -e "[32m$*[39m"
}

function delete_evil_cache() {
    green "\n\nDeleting NVIDIA cache directory at ~/.nv\n\n"
    rm -rf ~/.nv/
}

if [ "$(id -u)" != "0" ]; then
    echo "Install script must be run as root user"
    echo "Usage: sudo $0"
    exit
fi

delete_evil_cache

green "\n\nInstalling Bootstrap Requirements...\n\n"
install_bare_requirements

green "\n\nInstalling requirements for OpenAI Gym...\n\n"
install_openai_requirements

green "\n\nChecking System Hardware...\n\n"
src/sysinfo.py > info.json
cat info.json

green "\n\nChecking Operating System...\n\n"
src/check_os_version info.json || fail_msg "Error while checking OS version"

green "\n\nChecking Connected GPU cards...\n\n"
src/check_nvidia_cards info.json || fail_msg "Error while checking for available GPU cards"

delete_evil_cache

green "\n\nDownloading CUDA installer...\n\n"
download_cuda || fail_msg "Error while downloading CUDA installer"

green "\nAttempting to disable Nouveau...\n"
sudo modprobe -r nouveau || fail_msg "Error disabling Nouveau"
sudo update-initramfs -u

green "\nAttempting to install NVIDIA drivers and CUDA...\n"
chmod +x $CUDA_VERSION
sudo ./$CUDA_VERSION --silent --no-drm --no-opengl-libs --verbose --driver --toolkit || fail_msg "Error installing CUDA"

nvidia-smi || fail_msg "Failed to run nvidia-smi, drivers are not properly installed"
green "NVIDIA drivers are installed"

green "\nAdding nvcc to the path...\n"
echo 'export PATH=$PATH:/usr/local/cuda-9.0/bin' >> ~/.profile
source ~/.profile

green "\nChecking for nvcc install...\n"
nvcc -V || fail_msg "Error: Could not find nvcc"
green "CUDA utilities are installed"

green "\nAdding cuda .so to the library path...\n"
echo '/usr/local/cuda-9.0/lib64/' >> /etc/ld.so.conf
ldconfig
green "CUDA libraries are installed"

green "\nChecking for libcuda.so...\n"
ldconfig -p | grep libcuda || fail_msg "libcuda.so is not on the LD_LIBRARY_PATH"

green "\nDownloading CUDNN...\n"
green "\n(You agree to all NVIDIA terms and conditions)\n"
wget -nc $CUDNN_URL || fail_msg "Failed to download cudnn-*.tgz"
sha256sum cudnn-9.0-linux-x64-v7.tgz | grep $CUDNN_SHA256 || fail_msg "Bad SHA256 hash for cudnn-*.tgz"

green "\nInstalling CUDNN...\n"
tar xzvf cudnn-9.0-linux-x64-v7.tgz -C /usr/local || fail_msg "Failed to extract CUDNN libraries"
ldconfig
ldconfig -p | grep cudnn || fail_msg "Failed to find cudnn.so"
green "CUDNN libraries are installed"


green "Creating a Python 3 virtual environment..."
virtualenv -p python3 venv
source venv/bin/activate

green "Installing PyTorch to $PWD/venv..."
pip3 install http://download.pytorch.org/whl/cu90/torch-0.3.1-cp35-cp35m-linux_x86_64.whl
pip3 install torchvision

python src/torch_mnist.py --epochs 1 || fail_msg "Failed to run PyTorch test"
green "PyTorch works correctly"

green "Installing Tensorflow..."
pip install keras tensorflow-gpu
green "Running Tensorflow example..."
python src/tensorflow_mnist.py || fail_msg "Failed to run Tensorflow test"
green "Tensorflow works correctly"

green "Installing Keras..."
pip install --upgrade keras

green "Running Keras example..."
python src/keras_mnist_gan.py || fail_msg "Failed to run Keras test"
green "Keras works correctly"

USER_NAME=$(printf '%s' "${SUDO_USER:-$USER}")
chown -R $USER_NAME venv
green "Setting permissions on venv/ to user $USER_NAME"

green "Installed Versions:"
pip freeze | grep tensorflow
pip freeze | grep torch
pip freeze | grep keras
nvcc --version | grep release
nvidia-smi --help | head -1

delete_evil_cache

echo -n "Successfully installed PyTorch/Tensorflow/Keras to $PWD/venv"
echo
echo -n "Do you want to permanently use $PWD/venv as your default Python environment? (y/n) > "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Adding $PWD/venv/bin/activate to ~/.profile"
    echo "source $PWD/venv/bin/activate" >> ~/.profile
fi
