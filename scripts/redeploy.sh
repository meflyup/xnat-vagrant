#!/bin/bash

# This script is to be executed from inside the VM to redeploy
# a previously deployed web app or deploy a newly download war.

OWD=${PWD}

# Exit with error status
die() {
    echo >&2 "$@"
    exit -1
}

[[ -e vars.sh  ]] || die "vars.sh file is required for redeploy script"

source vars.sh

echo
echo Stopping Tomcat...
sudo service tomcat7 stop

echo
echo Deleting web app and redeploying XNAT...

sudo rm -Rf /var/lib/tomcat7/webapps/ROOT*

echo

if [[ -e /vagrant/${XNAT_SRC##*/} && ${XNAT_SRC##*/} == *.war  ]]; then
    echo Copying war file...
    cp -fv /vagrant/${XNAT_SRC##*/} /var/lib/tomcat7/webapps/ROOT.war
elif [[ -e ${DATA_ROOT}/src/${XNAT_DIR}/build/libs/ROOT.war ]]; then
    echo Copying war file...
    cp -fv ${DATA_ROOT}/src/${XNAT_DIR}/build/libs/ROOT.war /var/lib/tomcat7/webapps/ROOT.war
else
    die "XNAT war file not found."
fi

# Reset database?
DESTROY=N
echo
read -p "Would you like to reset the database? ALL DATABASE DATA IN THIS VM WILL BE DESTROYED. [y/N] " DESTROY

if [[ $DESTROY =~ [Yy] ]]; then
    echo
    echo "Dropping '${PROJECT}' database."
    dropdb -U $VM_USER $PROJECT
    echo
    echo "Creating new '${PROJECT}' database."
    createdb -U $VM_USER $PROJECT
fi

echo
echo Restarting Tomcat...
sudo service tomcat7 start || die "Tomcat startup failed."

echo
echo Rebuild complete.
echo