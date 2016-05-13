#!/bin/bash
#
# XNAT Vagrant provisioning script
# http://www.xnat.org
# Copyright (c) 2016, Washington University School of Medicine, all rights reserved.
# Released under the Simplified BSD license.
#

SOURCE=$(basename -- ${BASH_SOURCE[0]})
echo Now running the "${SOURCE}" provisioning script.

# Check if there's a vars.sh specified. If not, then copy the default template in.
[[ ! -d /vagrant/.work ]] && { mkdir /vagrant/.work; }
[[ ! -f /vagrant/.work/vars.sh ]] && { cp /vagrant-multi/templates/vars.sh.tmpl /vagrant/.work/vars.sh; }

sourceScript() {
    test -f /vagrant/scripts/$1 && source /vagrant/scripts/$1 || source /vagrant-multi/scripts/$1    
}

# Now initialize the build environment from the config's vars.sh settings.
source /vagrant/.work/vars.sh

# look in config's scripts folder first, then try the multi root
sourceScript macros.sh
sourceScript defaults.sh

# Update the VM.
sudo apt-get update

# Install any additional specified packages
if [ -v INSTALL ]; then
    echo "Installing additional packages: ${INSTALL}"
    sudo apt-get -y install ${INSTALL}
fi

# Create XNAT user
#  1. Create user group
#  2. Create user. Flags:
#       -g initial_group        User's initial login group
#       -G group[,...]          Supplementary groups of which user is a member
#       -d home_dir             User's login directory
#       -m                      Create home_dir if it does not exist
#       -s shell                User's login shell
echo ""

echo "Creating XNAT user with the home directory ${HOME}"
ROOT="$(dirname ${HOME})"
sudo [ ! -d ${ROOT} ] && { mkdir -p ${ROOT}; }
sudo groupadd ${VM_USER}
sudo useradd -g ${VM_USER} -G users,docker -d ${HOME} -m -s /bin/bash ${VM_USER}

# Create the VM user's bash profile.
echo ""
echo "Creating XNAT user's bash profile"
replaceTokens bash.profile | sudo tee ${HOME}/.bash_profile

# Set up ssh keys for VM user.
echo ""
echo "Copying vagrant ssh keys"
sudo cp -R /home/vagrant/.ssh ${HOME}

# Now make anything non-VM_USER-y VM_USER-y.
sudo chown -R ${VM_USER}.${VM_USER} ${HOME}

# Add VM user to list of NOPASSWD sudoers.
echo ""
echo "Adding XNAT user to list of NOPASSWD sudoers"
replaceTokens sudoers.d | sudo tee /etc/sudoers.d/${VM_USER}

# Set up Docker to listen for external connections
echo ""
echo "Creating Docker service configuration file"
sudo mkdir /etc/systemd/system/docker.service.d
replaceTokens docker.conf | sudo tee /etc/systemd/system/docker.service.d/docker.conf
