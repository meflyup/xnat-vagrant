#!/bin/bash

mkdir -p .work
if [[ ! -z $1 ]]; then
    printf $1 > .work/config
else
    rm -f .work/config
fi

echo
echo Starting XNAT build...
echo

echo Provisioning VM with specified user...
vagrant up

echo Reloading VM configuration to configure folder sharing...
vagrant reload

echo Running build provision to build and deploy XNAT on the VM...
vagrant provision --provision-with build

#rm -f .work/config
echo Provisioning completed.
