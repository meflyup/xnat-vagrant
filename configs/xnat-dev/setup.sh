#!/bin/bash

#mkdir -p .work

echo
echo Starting XNAT build...

echo
echo Provisioning VM with specified user...

echo
vagrant up

#if [[ -f .work/vars.sh ]]; then
#
#    source .work/vars.sh
#
#    # xnat_src MUST be set for this VM to build properly
#    if [[ $XNAT_SRC == '' ]]; then
#
#        echo
#        echo "XNAT_SRC is empty. Please set the directory path to your XNAT source as "
#        echo "the value for 'xnat_src' in your 'local.yaml' file and run setup again."
#        exit
#
#    fi
#
#fi

echo
echo Reloading VM configuration to configure folder sharing...

echo
vagrant reload

echo
echo Running build provision to build and deploy XNAT on the VM...

echo
vagrant provision --provision-with build

echo
echo Provisioning completed.
