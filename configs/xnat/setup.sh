#!/bin/bash

mkdir -p .work
if [[ ! -z $1 ]]; then
    printf $1 > .work/config
else
    rm -f .work/config
fi

echo
echo Downloading XNAT and Pipeline war files...

ftp_base=ftp://ftp.nrg.wustl.edu/pub/xnat

xnat_war=xnat-web-1.7.0-SNAPSHOT.war
pipeline_zip=xnat-pipeline-1.7.0-SNAPSHOT.zip

xnat_url=${ftp_base}/${xnat_war}
pipeline_url=${ftp_base}/${pipeline_zip}

if [[ ! -f ${xnat_war} ]]; then
    echo
    echo Downloading: ${xnat_url}
    curl -O ${xnat_url} \
    || echo "Error downloading '${xnat_url}'"
fi

if [[ ! -f ${pipeline_zip} ]]; then
    echo
    echo Downloading: ${pipeline_url}
    curl -O ${pipeline_url} \
    || echo "Error downloading '${pipeline_url}'"
fi

echo
echo Starting XNAT build...

echo
echo Provisioning VM with specified user...
echo
vagrant up

echo
echo Reloading VM configuration to configure folder sharing...
echo
vagrant reload

echo
echo Running build provision to build and deploy XNAT on the VM...
echo
vagrant provision --provision-with build

#rm -f .work/config
echo Provisioning completed.
