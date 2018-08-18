## System Python

On a typical Ubuntu system, you probably have Python 2.7 installed in `/usr/bin/python`.
People sometimes call this the "system Python".
This version of Python has a version of Pip (installed with `sudo apt install python-pip`) at `/usr/bin/pip`.

So if you don't install virtualenv or pyenv or anaconda, then when you run:

    python

it runs `/usr/bin/python`, and when you run:

    pip

it runs `/usr/bin/pip`.

You can verify this with the `which` command, a command that checks all the directories in your `$PATH` to tell you which version of a command is first in the path.

    $ which python
    /usr/bin/python
    $ which pip
    /usr/bin/pip

The system version of pip will install packages to somewhere like `/usr/local/lib/python2.7/dist-packages/`.

Ove the years a few problems emerged:

- People want to use pip without sudo, and installing things into `/usr/local/lib/python2.7/dist-packages` requires sudo
- People want to use Python 3, but you can't just replace `/usr/bin/python` with Python 3 because it breaks lots of other software (many packages require Python 2.7 to be in `/usr/bin/python`)
- People want to run many different Python applications on one computer, but sometimes applications' requirements disagree. For example, foo.py might require the installed version of Numpy to be 1.9 but bar.py might only work with version 1.8.

To fix these problems we use Virtualenv, Anaconda, or Pyenv to set up alternative Python installations in addition to `/usr/bin/python`.


## An aside: the `$PATH` variable

In your terminal, you can always run a command by specifying its full path, starting with `/`

    $ /bin/pwd
    /home/myname

    $ /bin/date
    Sat Aug 19 14:04:42 PDT 2028

    $ /usr/bin/who
    myname   pts/0        2018-08-17 13:24 (192.168.1.150)

    $ /home/myname/bin/hello
    Hello, World!


This works, but it quickly becomes annoying because you have to memorize which commands are in `/bin/` and which commands are in `/usr/bin/`.
When you start using other directories like `/home/myname/bin/` it becomes too much to type.
It would be nice if you could just type the name of a command, (for example, `pgrep`) and have the computer automatically run the following:

    If `pgrep` is in `/bin/` then run `/bin/pgrep`.
    Else if `pgrep` is in `/usr/bin` then run `/usr/bin/pgrep`
    Else if `pgrep` is in `/usr/local/bin` then run `/usr/local/bin/pgrep`
    ...

This is what your shell does when you run any command that does not start with a `/` forward slash.
The list of directories that the shell checks to find your command is `$PATH`.

The `$PATH` is a list of directory names with colons in between them (it is "colon-delimited").
It looks like this:

    $ echo $PATH
    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

`$PATH` is an *environment variable* for your shell.
This means that you can set it with `PATH=` and you can print its value with `echo`:

    $ PATH=/usr/local/bin:/usr/sbin:/bin:/usr/bin
    $ echo $PATH
    /usr/local/bin:/usr/sbin:/bin:/usr/bin

Usually you want to add something to `$PATH`, either at the start or at the end.
You can do that by setting the new `PATH` to something new, plus the old `$PATH`:

    $ PATH=/home/myname/mybin:$PATH
    $ echo $PATH
    /home/myname/mybin:/usr/local/bin:/usr/sbin:/bin:/usr/bin

Now, whenever you type

    $ foobar
    
the shell will run `/home/myname/mybin/foobar` if that file exists and is executable.
If it doesn't exist, then the shell will look for `/usr/local/bin/foobar`, and so on for each directory in `$PATH`.

Note that `$PATH` is an environment variable, which means that any change you make to it will only affect your current terminal session.
If you want to change the `$PATH` for all programs spawned by your shell, you need to use the `export` command.
If you want to change the `$PATH` for every shell session every time you log in, you need to add that `export` command into your `~/.profile` or `~/.bashrc` configuration file.

For example, you might open your profile:

    $ nano ~/.profile

and add a line to the bottom of the file:

    export PATH=$PATH:/home/myname/mybin

Now if you make your own program called `foobar` and place it in `/home/myname/mybin/foobar`, you will be able to run `foobar` at any time, no matter which directory you are in.


### An Exercise

Let's say we have a shell script called `myprog.sh`.
Let's see what happens if we rename that file to "python" and place it into a directory in our `$PATH`.

    $ cat myprog.sh
    #!/bin/bash
    echo Hello World!

    $ chmod +x myprog.sh
    $ cp myprog.sh /home/myname/mybin/python
    $ export PATH=/home/myname/mybin:$PATH

Now, we have (temporarily) replaced `python` with our own executable, also named `python`.
If we try to run `python` we will see the following:

    $ python
    Hello World!

Questions:

- What does `which python` output *before* we run the `export` command?
- What does `which python` output *after* we run the `export` command?
- What would have happened if we instead ran `export PATH=$PATH:/home/myname/mybin`?


## Virtualenv

You might install Python 3.5 with Virtualenv, like this:

    $ which python
    /usr/bin/python

    $ echo $PATH
    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

    $ virtualenv -p python3.5 venv35
    Running virtualenv with interpreter /usr/bin/python3.5
    Using base prefix '/usr'
    New python executable in /home/myname/venv35/bin/python3.5
    Also creating executable in /home/myname/venv35/bin/python
    Installing setuptools, pkg_resources, pip, wheel...done.

    $ source venv35/bin/activate

    (venv35) $ which python
    /root/venv35/bin/python

    (venv35) $ echo $PATH
    /root/venv35/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games

Now that you understand the `$PATH`, you can see what is going on here.
Running `virtualenv` just creates a directory (in this case, `venv35`) and copies a `python` executable into that directory (in this case, a copy of Python 3.5)
Running the `activate` script for a virtualenv just adds a new directory to the beginning of your PATH, so that when you later run `python`, it looks in the virtualenv directory first.

If you run `which pip` after activating a virtualenv, you will notice that the `venv35/bin` directory also has its own copy of pip.
When you use this copy of pip to install packages, the packages are installed into the virtualenv, in `venv35/lib/pyton3.5/site-packages`.

Note that packages installed into the virtualenv are not available to the system Python, and packages installed for the system python are not necessarily available to the virtualenv.


## Pyenv

Pyenv can be used as a kind of replacement for virtualenv, or alongside it.
For information about Pyenv, [read the Pyenv docs](https://github.com/pyenv/pyenv#how-it-works)

## Anaconda

Anaconda works in a similar way to virtualenv and is used by some in the research community.
For information on Anaconda, read [the conda docs](https://conda.io/docs/glossary.html#miniconda-glossary)
