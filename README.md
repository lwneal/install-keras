# Install Keras
Keras is very powerful, but it is very frustrating to install. Follow this guide to install GPU-enabled Keras on Ubuntu.


## Step Zero
You'll want to start with a system running Ubuntu: 14.04 or 16.04 should work fine. A fresh install is recommended. The system will need at least one Nvidia GPU card, preferably a GTX780 or newer. You will need root access.


## Step One: Drivers

First you need NVIDIA drivers. Note that these are NOT the default, open source drivers that ship with Ubuntu (those drivers are called Nouveau). What you need is the proprietary binary-only driver directly from Nvidia Inc, not from apt-get. You can download the latest drivers here:

http://www.nvidia.com/Download/index.aspx

If you download them in the "runfile" format, just chmod +x the file and run it, like:

    chmod +x ./NVIDIA-Linux-x86_64-384.90.run
    sudo ./NVIDIA-Linux-x86_64-384.90.run

Note that in order to install the drivers, you might have to uninstall Noveau, turn off the graphical X server (so, you might want to do all of this over SSH or with ctrl+alt+f1) and reboot the computer once or twice.

If all goes well, you will be able to run the command "nvidia-smi" and get some output like this:

```
π nvidia-smi
Sun Mar  5 21:00:53 2017
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 375.39                 Driver Version: 375.39                    |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  GeForce GTX 1080    Off  | 0000:01:00.0     Off |                  N/A |
|  0%   47C    P0    37W / 215W |      0MiB /  8114MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
```


## Step Two: CUDA

Now you need CUDA. You can download it here:

https://developer.nvidia.com/cuda-downloads

Get CUDA 8, the current version. (Warning: CUDA fails if used with drivers that are too old OR too new).

Select Linux -> x86_64 -> Ubuntu -> runfile

Download the runfile, make it executable, and run it:

    chmod +x cuda_8.0.61_375.26_linux-run
    sudo ./cuda_8.0.61_375.26_linux-run

You will be prompted with a long legal agreement. Hold space to skip through it then type "accept".

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


## Step Three: $PATH and $LD_LIBRARY_PATH

You thought you installed CUDA, but it's not that easy! By default, Tensorflow does not know where CUDA is installed: you need to add the CUDA installation directory to your path.

First, you need the `nvcc` program to be on your path. Append a line to your .profile or .bashrc to add `/usr/local/cuda/bin/` to the `$PATH` used to search for executables. Here's a one-liner which will do that:

    echo 'export PATH=$PATH:/usr/local/cuda/bin' >> $HOME/.profile; source $HOME/.profile

NOTE: Make sure that `/usr/local/cuda/bin` is on the path of EVERY user who needs to use CUDA-based tools like Keras.

If all went well, you should be able to run nvcc from any directory without specifying its full path:

    π nvcc -V
    nvcc: NVIDIA (R) Cuda compiler driver
    Copyright (c) 2005-2016 NVIDIA Corporation
    Built on Tue_Jan_10_13:22:03_CST_2017
    Cuda compilation tools, release 8.0, V8.0.61

Now you can run `nvcc`, but you're not done yet- eventually you're going to get an error like this:

    libcudart.so.8.0: cannot open shared object file: No such file or directory

The problem is that CUDA is not installed to `/usr/lib/` like a normal library: it's installed in `/usr/local/cuda/lib64/`. To fix this, add CUDA's library directory to the `$LD_LIBRARY_PATH` variable, which is like `$PATH` for libraries instead of executables.

    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.profile
    source ~/.profile

If all went well, the following incantations will run and print the correct versions of each library.

    function lib_installed() { /sbin/ldconfig -N -v $(sed 's/:/ /' <<< $LD_LIBRARY_PATH) 2>/dev/null | grep $1; }
    function check() { lib_installed $1 && echo "$1 is installed" || echo "ERROR: $1 is NOT installed"; }
    check libcuda
    check libcudart

If the previous commands all worked, you can now run code on your GPU. Of course, implementing neural networks in CUDA by hand would take forever, so instead of writing CUDA C, we want to write Python and use a tool that will write the C code for us. That tool is called Tensorflow.


## Step Four: CuDNN

Before installing Tensorflow, we require another extra library from NVIDIA, CuDNN. This is a library of specialized fast neural network functions.

To download a copy of CuDNN, Nvidia requires you to create an account and answer some questions at their site here:

https://developer.nvidia.com/cudnn

Or, here's a mirror:

    wget http://lwneal.com/libcudnn5_5.1.5-1+cuda8.0_amd64.deb

Install the .deb package:

    sudo dpkg -i libcudnn5_5.1.5-1+cuda8.0_amd64.deb

After this, you should see a `libcudnn.so.5` in `/usr/lib` somewhere:

    π find /usr | grep libcudnn
    /usr/lib/x86_64-linux-gnu/libcudnn.so.5.1.5
    /usr/lib/x86_64-linux-gnu/libcudnn_static_v5.a
    /usr/lib/x86_64-linux-gnu/libcudnn.so.5

If all went well, the following commands should not print errors:

    function lib_installed() { /sbin/ldconfig -N -v $(sed 's/:/ /' <<< $LD_LIBRARY_PATH) 2>/dev/null | grep $1; }
    function check() { lib_installed $1 && echo "$1 is installed" || echo "ERROR: $1 is NOT installed"; }
    check libcudnn


## Step Five: Virtualenv

Now we have installed all of the underlying libraries and tools required for Tensorflow, so we can finally install Tensorflow itself... almost.

We actually still need to install one more thing: Python Virtualenv.

### Aside: The Problem with Pip

If you've used Python with Ubuntu, you're probably used to typing the following command:

    pip install foobar

then seeing a bunch of angry red text in your terminal, and typing

    sudo pip install foobar

When you run this command, you are using the pip program, which is `/usr/bin/pip` or `/usr/local/bin/pip`, to download some files and copy them into `/usr/local/lib/python2.7/dist-packages/foobar`. You are doing this as the root account (sudo) because your regular user account does not have permission to write to files inside of `/usr/`. The copies of Python and Pip that you are using exist inside the `/usr` folder, and are called the "system version" of Python.

In Google-Land, where Tensorflow is developed, folks don't use `/usr/bin/python`. Instead, they create a _virtual environment_ for each project. This creates a new copy of Python like `/home/username/venvname/bin/python`. The main reason for this is to enable each project to depend on a specific version of all its libraries. For example, project Foo might only work with numpy version 1.9, and project Bar might only work with numpy 1.11. Putting each project in its own Python environment is the only way to get both of them to run at the same time. Tensorflow tends to crash if you're not using a virtual environment.


### The Solution

To run Tensorflow without crashing, use Virtualenv. Virtualenv downloads and installs a clean, brand new, unencumbered version of Python into a directory that you choose. To install Virtualenv and create a new virtual environment, run:

    sudo apt-get install virtualenv
    sudo easy_install virtualenv
    virtualenv $HOME/venv

To make your virtual environment the default Python installation that you use whenever you log in, run:

    echo 'source venv/bin/activate' >> $HOME/.profile
    source $HOME/.profile

Now your prompt should start with `(venv)` to indicate that the virtual environment is working.
To confirm that you are using Virtualenv, open a new terminal window and run `which python`. You should see something like this:

    (venv) λ which python
    /home/nealla/venv/bin/python
    (venv) λ which pip
    /home/nealla/venv/bin/pip

Now you're using virtualenv. From now on, you can use `pip` without typing `sudo`. If you ever have problems with Python, you can delete your whole virtualenv and create a new one with `rm -rf $HOME/venv; virtualenv $HOME/venv`.


## Step Six: Tensorflow

Now you have the whole CUDA stack and a version of Python that might work with Tensorflow. Install GPU-enabled Tensorflow:

    pip install tensorflow-gpu

If all went well, you should be able to open up a Python instance and run Tensorflow, and it should use your GPU. Example:

```
python -c 'from tensorflow.python.client import device_lib; print device_lib.list_local_devices()'
[name: "/cpu:0"
device_type: "CPU"
memory_limit: 268435456
locality {
}
incarnation: 9264816745167862008
, name: "/gpu:0"
device_type: "GPU"
memory_limit: 7969613415
locality {
  bus_id: 1
}
incarnation: 6723032879396465433
physical_device_desc: "device: 0, name: GeForce GTX 1080, pci bus id: 0000:01:00.0"
]
```

You should see at least one GPU device listed.


## Step Seven: Keras

At this point, all the hard work is done. Just install Keras.

    pip install keras

You should be able to `import keras` and start building models.


## Step Eight: H5Py

The first time you run demonstration Keras code, you'll probably get an error like this:

    ImportError: No module named h5py

If `pip install h5py` does not work, try `sudo apt-get install python-h5py`.

