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
  `./run xnat-latest setup`, etc.

### List of commands:
  - `./run xnat setup`   - initial VM setup - *this **must** be performed first to create the VM
  - `./run xnat stop`    - shuts down the VM
  - `./run xnat start`   - (re)launches a VM that has been set up but is not running
  - `./run xnat destroy` - deletes the VM and related files

The `run` script is more or less a proxy for the `vagrant` commands, allowing you to work with multiple VMs
from a single 'root' folder. You can also choose to navigate to each individual config folder and run the
Vagrant commands directly.
