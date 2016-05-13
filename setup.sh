#!/bin/bash

#source scripts/get-configs.sh

CONFIG=xnat

mkdir -p .work
if [[ ! -z $1 ]]; then
    CONFIG=$1
fi

printf $CONFIG > .work/config

echo
echo "Starting XNAT build using '${CONFIG}' config..."

# run the setup scripts and Vagrant commands from the config folder
cd ./configs/$CONFIG

bash ./setup.sh

echo
echo Provisioning VM with specified user...
vagrant up

echo
echo Reloading VM configuration to configure folder sharing...
vagrant reload

echo
echo Running build provision to build and deploy XNAT on the VM...
vagrant provision --provision-with build

echo
echo Provisioning completed.
