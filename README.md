XNAT Vagrant
==============================

This is the primary release repository for the [XNAT](http://www.xnat.org) Vagrant project. You may find a more up-to-date version of this project on the corresponding [xnat-vagrant Bitbucket repository](https://bitbucket.org/xnatdev/xnat-vagrant), but you may also find a more __unstable__ version there as well. Updates will be pushed to this repository as they are tested and verified by the XNAT development team.

## Note

Windows users will need a Bash terminal program - **Cygwin** or **Git Bash** are recommended. Git Bash is
installed by default when you run the Git installer and should work for running the scripts in this repo.

## Quick-Start

- Make sure you have [Git](https://git-scm.com/downloads), [Vagrant](https://www.vagrantup.com),
  and [VirtualBox](https://www.virtualbox.org) installed on your host machine.
- Clone the repo: `git clone https://bitbucket.org/xnatdev/xnat-workshop-vms.git`
- From inside the `xnat-workshop-vms` folder, run `./run xnat-11 setup` to launch and configure the first VM.
  Other VM configurations can be set up similarly, substituting the folder name of the config:
  `./run xnat-12 setup`, etc.

### List of commands:
  - `./run xnat-11 setup` - initial VM setup - *this **must** be performed first to create the VM*
  - `./run xnat-11 stop` - shuts down the VM
  - `./run xnat-11 start` - (re)launches a VM that has been set up but is not running
  - `./run xnat-11 destroy` - deletes the VM and related files

The `run` script is more or less a proxy for the `vagrant` commands, allowing you to work with multiple VMs
from a single 'root' folder. You can also choose to navigate to each individual config folder and run the
Vagrant commands directly.
