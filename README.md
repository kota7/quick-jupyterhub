Quick JupyterHub on Docker
==========================

This perhaps is one of the simplest deployment of [JupyterHub](https://jupyterhub.readthedocs.io/en/stable/) using a docker container.
Unfortunately, the [official jupyterhub image](https://github.com/jupyterhub/jupyterhub/) is not designed for an immediate use, and requires several configurations before running it.
Building on the official image, this image adds as simple configuration as possible to be able to deploy quickly.
It is not meant to be scalable to hundreds of users, but would still work just fine for small teams.



## Usage

```shell
# build
$ docker build -t quick-jupyterhub .

# run
$ docker run --rm -d -p 8000:8000 -v quickjh_home:/home --name quickjh quick-jupyterhub
```

You can then open the JupyterHub at [http://localhost:8000/](http://localhost:8000/) on your browser.
There are users named `admin` and `user1` already, and their passwords are the same as the username.

## Add, delete, modify users

In this configuration, the set of JupyterHub users is identical to the set of linux users in the system.
So we can manipulate users just like we do in the linux system (the OS is ubuntu).
Login with `admin`, and open the terminal. Then, modify users by linux commands.
When you create a user, make sure you also create `/home/<username>/notebook` directory (otherwise jupyterhub fails at this user's login).
Also, the user must own the home directory to properly operate via the JupyterHub interface.

```shell
# add user (change user2 to any name valid in the linux convention)
$ sudo useradd -m user2 && \
  sudo mkdir /home/user2/notebook && \
  sudo chmod 700 /home/user2 && \
  sudo chown -R user2: /home/user2

# delete
$ sudo userdel -r <username>

# change password by admin
$ sudo passwd <username>

# change password by the user
$ passwd
```

## Add python packages and others

This system is `pip` based (not `conda`).
So users basically should install packages via `pip` command either on the terminal or on the notebook cells (Use `%pip` magic).
Packages installed by a user is stored under the user's home directory and are not viewable by other users.
This way, user environments are natually separated.
We have installed a few fundamental packages as root (particularly ones needed for running jupyter), which are shared among all users.
To share more packages among users, login as admin and call `sudo pip` from the terminal.
This can save disk space, but may also cause version compatibility problems.

If we need external software to supplement the python packages, e.g. `apt install` is needed, then we need to ask admin user since we need `sudo` for this.
And the `apt`-based software is shared among all users (since we share the same system. We may see this as the limitation of this approach).

## Integrate conda-based environemnt

Users may install `miniconda` on their home directory and build package environment using the `conda` feature (`conda create`).
That environment can be added to the juptyer kernel and can be used from notebooks.
This can be a favorable option since `conda` allows us to manage not only python packages but other languages and external software.
Note that `conda` command won't work on the notebook cell, and `pip` would point to the root `pip`, instead of the one in the conda env.
So, package installation must be done in the terminal.
When you use `pip`, make sure you are using the one you intend by checking `which pip`.

Here is a commnd example to make a conda-env and add it into the kernel.

```shell
$ conda create -n testenv -y numpy tqdm ipykernel
$ conda activate testenv
$ python -m ipykernel install --user --name testenv_conda --display-name "testenv(conda)"
```
We should see the new kernel after refreshing the browser.
Note that with `--user` option the kernel is added to the kernelspec under the user's home directory, and thus not visible by other users.


We don't recommend system-wide install of `conda` since user permission is not easy to manage with it.


## Make data persistent

### User notebooks and files

The containers are ephemerial in a sense that files created during the container processes are discarded when the container is destroyed.
Such files include users' notebooks and related files, which we don't want to lose.
In order to keep these files persistent, we can use the [docker's volume feature](https://docs.docker.com/storage/volumes/).
This is why we have `-v` option in the `docker run` command above.

This command creates a docker-managed volume named `quickjh_home` and this stays alive unless you remove it (or docker itself is gone).
This means, if you `docker stop quickjh` and run the image again, then you have the same user files in the container.

### Added users and passwords

We may also want to keep the user list and their passwords, possibly changed during the session even after the container termination.
A quick (and a bit ugly) way of doing this is to apply the docker volume to `/etc` directory, since user information is stored there.
However, since that directory contains a number of other files as well (and some are sensitive), this may cause some problem (especially when the container's OS updates. Perhaps there is no problem so long as we are reusing the same image).
To take this approach, the launcher code will have another `-v` option like below:

```shell
$ docker run --rm -d -p 8000:8000 -v quickjh_home:/home  -v quickjh_etc:/etc --name quickjh quick-jupyterhub
```

Note that if we lose the users and their passwords, we still have their data by the persistent volume.
This means we only lose user's login capability, not their works.
We can recover this loss by redefining users based on the names of the subdirectories under `/home`.

```shell
# add user with home directory
# omit -m option since directory already exists
$ sudo useradd missinguser
```

Since the recovery is not so hard, in some use cases it can be a reasonable choice to give up persisting the user list and passwords.
