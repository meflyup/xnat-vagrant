#!/bin/bash

# wipe out .vagrant folder - it will be recreated
[[ -d .vagrant ]] && rm -R .vagrant

#echo
#echo Downloading XNAT and Pipeline war files...

mkdir -p ../../local/downloads
DL_DIR=../../local/downloads

getConfigValueFromFile() {
    echo $(grep ^$2 $1 | cut -f 2- -d : | sed -e 's/#.*$//' | sed -e 's/^[[:space:]]*//')
}

getConfigValue() {
    local VALUE=$(getConfigValueFromFile config.yaml $1)
    [[ -f local.yaml ]] && VALUE=$(getConfigValueFromFile local.yaml $1)
    echo $VALUE
}

XNAT_URL=$(getConfigValue xnat_url)
PIPELINE_URL=$(getConfigValue pipeline_url)

XNAT_WAR=${DL_DIR}/${XNAT_URL##*/}
PIPELINE_ZIP=${DL_DIR}/${PIPELINE_URL##*/}

doDownload() {
    [[ -e $1 ]] && rm $1
    echo
    echo Downloading from configured URL: $2
    cd ${DL_DIR}
    curl -k -L --retry 5 --retry-delay 5 -O $2 || echo "Error downloading $1"
    cd -
}

downloadPrompt(){
    local choice=x
    if [[ -e $1 ]]; then
        read -p "${2##*/} has already been downloaded. Type 'y' to download a new copy or 'n' to continue. " choice
    else
        choice=y
    fi
    if [[ ! $choice =~ [YyNn] ]]; then
        downloadPrompt $1 $2
    else
        [[ $choice == y ]] && doDownload $1 $2
    fi
}

downloadPrompt ${XNAT_WAR} ${XNAT_URL}
downloadPrompt ${PIPELINE_ZIP} ${PIPELINE_URL}

echo
echo Starting XNAT build...

echo
echo Provisioning VM with specified user...

echo
vagrant up

echo
echo Reloading VM to configure folder sharing...

echo
vagrant reload

echo
echo Running build provision to build and deploy XNAT on the VM...

echo
vagrant provision --provision-with build

echo
echo Provisioning completed.
