# Install Keras
Keras is the most amazing and beautiful tool ever created, but it's impossibly difficult to install and use.

This guide will try to map out one possible way to get it running.

# Step Zero
You'll want to start with a system running Ubuntu: 14.04 or 16.04 should work fine. A fresh install is recommended. The system will need an nvidia card, preferably a GTX680 or newer (older cards might work, but no guarantees). You will need root access.


# Step One

First you need NVIDIA drivers. Note that these are NOT the default, open source drivers that ship with Ubuntu (those drivers are called Noveau). What you need is the proprietary binary-only driver directly from Nvidia Inc, not from apt-get. You can download the latest drivers here:

http://www.nvidia.com/Download/index.aspx

If you download them in the "run file" format, just chmod +x the file and run it, like:

    ./NVIDIA-Linux-x86_64-367.35.run

Note that in order to install the drivers, you might have to uninstall Noveau, turn off the X server (so, you might want to do all of this over SSH or with ctrl+alt+f1) and reboot the computer once or twice.

If all goes well, you will be able to run the command "nvidia-smi" and get some output like this:

```
λ nvidia-smi
Sun Mar  5 13:48:42 2017
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 367.57                 Driver Version: 367.57                    |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce GTX 1080    Off  | 0000:01:00.0     Off |                  N/A |
| 51%   69C    P2   104W / 240W |   7825MiB /  8110MiB |     72%      Default |
+-------------------------------+----------------------+----------------------+
|   1  GeForce GTX 1080    Off  | 0000:04:00.0     Off |                  N/A |
| 41%   58C    P2    83W / 200W |   7829MiB /  8113MiB |     38%      Default |
+-------------------------------+----------------------+----------------------+
```


# Step Two

Now you need CUDA. You can download it here:

https://developer.nvidia.com/cuda-downloads

Get CUDA 8, the current version. (Warning: CUDA fails if used with drivers that are too old OR too new).

Select Linux -> x86_64 -> Ubuntu -> runfile

Download the runfile, make it executable, and run it:

    chmod +x cuda_8.0.61_375.26_linux-run
    sudo ./cuda_8.0.61_375.26_linux-run

You will be prompted with a ridiculous huge legal agreement. Hold space to skip through it then type "accept".

You might be asked to install the drivers again: if you already have working drivers (nvidia-smi works) then answer "no".

You will be asked to install the CUDA 8.0 Toolkit. Answer "yes".

You will be asked to install some demo programs and a link to `/usr/local/cuda`. Answer "yes".

If all goes well, after CUDA is installed, you should be able to run the following command:

    π /usr/local/cuda/bin/nvcc -V
    nvcc: NVIDIA (R) Cuda compiler driver
    Copyright (c) 2005-2016 NVIDIA Corporation
    Built on Tue_Jan_10_13:22:03_CST_2017
    Cuda compilation tools, release 8.0, V8.0.61

This means that the Nvidia compiler, `nvcc`, is installed. This is the compiler used to translate CUDA code (which looks like C) into machine code runnable by the GPU.

But wait! You're not done until the `nvcc` program is on your path. Append a line to your .profile or .bashrc to add `/usr/local/cuda/bin/` to the `$PATH` used to search for executables. Here's a one-liner which will do that:

    echo 'export PATH=$PATH:/usr/local/cuda/bin' >> $HOME/.profile; source $HOME/.profile

NOTE: Make sure that `/usr/local/cuda/bin` is on the path of EVERY user who needs to use CUDA-based tools like Keras.

If all went well, you should be able to run nvcc from any directory without specifying its full path:

    π nvcc -V
    nvcc: NVIDIA (R) Cuda compiler driver
    Copyright (c) 2005-2016 NVIDIA Corporation
    Built on Tue_Jan_10_13:22:03_CST_2017
    Cuda compilation tools, release 8.0, V8.0.61


At this point, you can finally actually run code on your GPU. Of course, implementing neural networks in CUDA by hand would take forever, so instead of writing CUDA C, we want to write Python and use a tool that will write the C code for us. That tool is called Tensorflow!


# Step Three

Before installing Tensorflow, we require another extra library from NVIDIA, CuDNN. This is a library of specialized fast neural network functions.

To download a copy of CuDNN, Nvidia requires you to create an account and answer some questions at their site here:

https://developer.nvidia.com/cudnn

Or you can download a copy from my site:

    wget http://lwneal.com/libcudnn5_5.1.5-1+cuda8.0_amd64.deb

Install the .deb package:

    sudo dpkg -i libcudnn5_5.1.5-1+cuda8.0_amd64.deb

After this, you should see a `libcudnn.so.5` in `/usr/lib` somewhere:

    π find /usr | grep libcudnn
    /usr/lib/x86_64-linux-gnu/libcudnn.so.5.1.5
    /usr/lib/x86_64-linux-gnu/libcudnn_static_v5.a
    /usr/lib/x86_64-linux-gnu/libcudnn.so.5

# Step Four

Now we have installed all of the underlying libraries and tools required for Tensorflow, so we can finally install Tensorflow itself... almost.

We actually still need to install one more thing: Python Virtualenv.

### The Problem

If you've used Python with Ubuntu, you're probably used to typing the following command:

    pip install foobar

then seeing a bunch of angry red text in your terminal, and typing

    sudo pip install foobar

When you run this command, you are using the pip program, which is `/usr/bin/pip` or `/usr/local/bin/pip`, to download some files and copy them into `/usr/local/lib/python2.7/dist-packages/foobar`. You are doing this as the root account (sudo) because your regular user account does not have permission to write to files inside of `/usr/`. The copies of Python and Pip that you are using exist inside the `/usr` folder, and are called the "system version" of Python.

In Google-Land, where Tensorflow is developed, folks *never* use the system Python. Instead, they create a _virtual environment_ for each project. Because all Google development is done using virtualenv, Google code tends not to work when used with system Python.

### The Solution

To run Tensorflow without crashing, use Virtualenv. Virtualenv downloads and installs a clean, brand new, unencumbered version of Python into a directory that you choose. To install Virtualenv and create a new virtual environment, run:

sudo apt-get install virtualenv
sudo easy_install virtualenv
virtualenv $HOME/venv

To make your virtual environment the default Python installation that you use whenever you log in, run:

echo 'source venv/bin/activate' >> $HOME/.profile
source $HOME/.profile

Now your prompt should start with (venv) to indicate that the virtual environment is working.
