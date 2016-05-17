XNAT Vagrant
==============================

This is the primary release repository for the [XNAT](http://www.xnat.org) Vagrant project. You may find a more up-to-date version of this project on the corresponding [xnat-vagrant Bitbucket repository](https://bitbucket.org/xnatdev/xnat-vagrant), but you may also find a more __unstable__ version there as well. Updates will be pushed to this repository as they are tested and verified by the XNAT development team.

## Note

On Windows, due to the way Git handles line endings (by default) when cloning, you will need to make
sure to preserve line endings when cloning this repo, otherwise provisioning the VM will fail.

## Quick-Start

Make sure you have Vagrant, Git, and VirtualBox installed on your computer, then run `./setup.sh`
(or `setup.bat` on Windows) from this folder to build an XNAT virtual machine for testing or development.
Optionally, you can run the setup script in any preset configuration folder (in subfolders of the 'configs' folder).

## Info

There are multiple configuration options to choose from for setting up your XNAT Vagrant VM.
These are in the 'configs' folder - please refer to the README files in the respective folders
for more information regarding each config.

## General Setup

Before you run the setup script, you'll need to have [Vagrant](https://www.vagrantup.com), [Git](https://git-scm.com/downloads),
and [VirtualBox](https://www.virtualbox.org) installed on your host machine.


*(more info to come...)*
