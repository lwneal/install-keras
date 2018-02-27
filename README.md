# Install PyTorch/Tensorflow/Keras/CUDA/CUDNN/etc

Deep Learning is amazing, but installing Keras is difficult.

This script will install all the requirements for you, automatically.


## Step One
Format your hard drive and install a brand new, clean fresh copy of Ubuntu Server 16.04


## Step Two
````
git clone https://github.com/lwneal/install-keras && cd install-keras && sudo ./install.sh
````


## Step Three

Have fun with deep learning. Check out the [PyTorch Examples](https://github.com/pytorch/examples).


## Troubleshooting

If anything goes wrong with your CUDA or CuDNN installations, I find the following helpful:

````
    sudo nvidia-uninstall
    sudo apt-get remove --purge nvidia-*
    sudo rm -r /usr/local/cuda*
````

Then try reinstalling everything again.
