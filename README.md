XNAT Vagrant
==============================

This is the working repository for the [XNAT](http://www.xnat.org) Vagrant project. You may find a more
stable, but older, version of this project on the corresponding
[xnat-vagrant GitHub repository](https://github.com/NrgXnat/xnat-vagrant).
Updates will be pushed to the GitHub repository as they are tested and verified by the XNAT development team.

## Note

Windows users will need a Bash terminal program - **Cygwin** or **Git Bash** are recommended. Git Bash is
installed by default when you run the Git installer and should work for running the scripts in this repo.

## Quick-Start

- Make sure you have [Git](https://git-scm.com/downloads), [Vagrant](https://www.vagrantup.com),
  and [VirtualBox](https://www.virtualbox.org) installed on your host machine.
- Clone the repo: `git clone https://bitbucket.org/xnatdev/xnat-vagrant.git`
- From inside the `xnat-vagrant` folder, run `./run xnat setup` to launch and configure a Vagrant VM using the
  [latest pre-built XNAT war file](https://bitbucket.org/xnatdev/xnat-web/downloads/xnat-web-1.7.0-SNAPSHOT.war).
  Other VM configurations can be set up similarly, substituting the folder name of the config:
  `./run xnat-latest setup`, etc. You can see the available configurations by listing the contents of the 
  **configs** folder. The currently available configurations are:
    * [xnat](configs/xnat/README.md) downloads the latest XNAT release bundle and installs it in the VM.
    * [xnat-dev](configs/xnat-dev/README.md) mounts XNAT source and pipeline folders into the VM to facilitate deploying XNAT development.
    * [xnat-latest](configs/xnat-latest/README.md) clones the XNAT web source folder to allow you to build the latest XNAT code inside the VM.
    * [xnat165-box](configs/xnat165-box/README.md) builds a VM using the XNAT 1.6.5 box image, which provides the XNAT 1.6.5 release server.

### List of commands:
  - `./run xnat setup`   - initial VM setup - *this **must** be performed first to create the VM
  - `./run xnat stop`    - shuts down the VM
  - `./run xnat start`   - (re)launches a VM that has been set up but is not running
  - `./run xnat destroy` - deletes the VM and related files

The `run` script is more or less a proxy for the `vagrant` commands, allowing you to work with multiple VMs
from a single 'root' folder. You can also navigate to each individual configuration folder and run the
**setup.sh** scripts or the Vagrant commands directly.

```bash
$ cd configs/xnat
$ ./setup.sh
```

In each folder, you can set up a file named **local.yaml** to customize various attributes of your Vagrant VM. Each folder contains a
version of **sample.local.yaml** that you can use as the starting point for your own **local.yaml** file. You can reference the
**config.yaml** file in that configuration to see the default values that are passed into the Vagrant configuration.