#!/bin/bash
# Works for Ubuntu Server 16.04 and CUDA 9.1

CUDA_VERSION="cuda_9.1.85_387.26_linux"
CUDA_URL="https://developer.nvidia.com/compute/cuda/9.1/Prod/local_installers/$CUDA_VERSION"
CUDNN_URL="http://downloads.deeplearninggroup.com/cudnn-9.1-linux-x64-v7.tgz"
CUDNN_SHA256="1ead5da7324db35dcdb3721a8d4fc020b217c68cdb3b3daa1be81eb2456bd5e5"

function install_bare_requirements() {
    apt install -y python python3 gcc make virtualenv
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


if [ "$(id -u)" != "0" ]; then
    echo "Install script must be run as root user"
    echo "Usage: sudo $0"
    exit
fi

green "\n\nInstalling Bootstrap Requirements...\n\n"
install_bare_requirements

green "\n\nChecking System Hardware...\n\n"
src/sysinfo.py > info.json

green "\n\nChecking Operating System...\n\n"
src/check_os_version info.json || fail_msg "Error while checking OS version"

green "\n\nChecking Connected GPU cards...\n\n"
src/check_nvidia_cards info.json || fail_msg "Error while checking for available GPU cards"

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
echo 'PATH=$PATH:/usr/local/cuda-9.1/bin' >> ~/.profile
source ~/.profile

green "\nChecking for nvcc install...\n"
nvcc -V || fail_msg "Error: Could not find nvcc"
green "CUDA utilities are installed"

green "\nAdding cuda .so to the library path...\n"
echo '/usr/local/cuda-9.1/lib64/' >> /etc/ld.so.conf
ldconfig
green "CUDA libraries are installed"

green "\nChecking for libcuda.so...\n"
ldconfig -p | grep libcuda || fail_msg "libcuda.so is not on the LD_LIBRARY_PATH"

green "\nDownloading CUDNN...\n"
green "\n(You agree to all NVIDIA terms and conditions)\n"
wget -nc $CUDNN_URL || fail_msg "Failed to download cudnn-*.tgz"
sha256sum cudnn-9.1-linux-x64-v7.tgz | grep $CUDNN_SHA256 || fail_msg "Bad SHA256 hash for cudnn-*.tgz"

green "\nInstalling CUDNN...\n"
tar xzvf cudnn-9.1-linux-x64-v7.tgz -C /usr/local || fail_msg "Failed to extract CUDNN libraries"
ldconfig -p | grep cudnn || fail_msg "Failed to find cudnn.so"
green "CUDNN libraries are installed"


green "Creating a Python 3 virtual environment..."
virtualenv -p python3 venv
source venv/bin/activate

green "Installing PyTorch to $PWD/venv..."
pip install http://download.pytorch.org/whl/cu90/torch-0.3.0.post4-cp35-cp35m-linux_x86_64.whl 
pip install torchvision

python src/torch_mnist.py --epochs 1 || fail_msg "Failed to run PyTorch test"
green "PyTorch works correctly"

echo "\nTODO: Skipping Tensorflow install until the Google bureaucracy supports CUDA 9.1"
#green "Installing Tensorflow..."
#pip install "https://pypi.python.org/packages/2d/15/8dbfa203f6dc6037b04ed00876a4e0439a3486f9f3211af9f0b1132e1374/tf_nightly_gpu-1.6.0.dev20180126-cp35-cp35m-manylinux1_x86_64.whl#md5=302e2f466ed3765dc3198380c353fe42"
#python src/tensorflow_mnist.py

echo -n "Successfully installed PyTorch to $PWD/venv"
echo -n "Use $PWD/venv as your default Python environment? (y/n) > "
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo "Adding $PWD/venv/bin/activate to ~/.profile"
    echo "source $PWD/venv/bin/activate" >> ~/.profile
fi
