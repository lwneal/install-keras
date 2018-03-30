# Install PyTorch/Tensorflow/Keras

Deep Learning is amazing, but installing the required tools can be difficult.

This script will download and install NVIDIA drivers, CUDA, CuDNN, and a Python 3 virtual environment including Pytorch, Tensorflow, and Keras.


## Requirements
Format your hard drive and install a brand new, clean fresh copy of Ubuntu Server 16.04


## Installation
````
git clone https://github.com/lwneal/install-keras && cd install-keras && sudo ./install.sh
````

If you see an error message, check the [Issues](https://github.com/lwneal/install-keras/issues) page.


## Deep Learning

Have fun with deep learning. Check out the [PyTorch Examples](https://github.com/pytorch/examples).


## Troubleshooting

If anything goes wrong with your CUDA or CuDNN installations, I find the following helpful:

````
    sudo nvidia-uninstall
    sudo apt-get remove --purge nvidia-*
    sudo rm -r /usr/local/cuda*
````

Then try reinstalling everything again.


## Alternatives

This script works if you are installing CUDA and related tools directly, on a machine that you have root access to.

If you have different requirements, you might be interested in Docker containers, pre-built AMI images, or services like [FloydHub](https://www.floydhub.com/).
