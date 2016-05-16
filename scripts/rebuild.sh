#!/bin/bash

# This script is to be executed from inside the VM to rebuild XNAT.
# Gradle will be executed and dependencies downloaded in the VM.

echo
echo Now running the "rebuild.sh" provisioning script.

source vars.sh

OWD=${PWD}

# Exit with error status
die() {
    echo >&2 "$@"
    exit -1
}

echo
echo Stopping Tomcat...
sudo service tomcat7 stop

echo
echo Rebuilding XNAT...

echo
echo Deleting web app and redeploying XNAT...

sudo rm -Rf /var/lib/tomcat7/webapps/ROOT*

echo

if [[ -e /vagrant/${XNAT_SRC##*/} && ${XNAT_SRC##*/} == *.war  ]]; then
    echo Copying war file...
    cp -fv /vagrant/${XNAT_SRC##*/} /var/lib/tomcat7/webapps/ROOT.war
else
    echo Executing Gradle build
    cd ${DATA_ROOT}/src/${XNAT_DIR}
    ./gradlew clean war --refresh-dependencies deployToTomcat
    cd $OWD
fi

# Reset database?
DESTROY=N
echo
read -p "Would you like to empty the database? ALL XNAT DATA IN THIS VM WILL BE DESTROYED. [y/N] " DESTROY

if [[ $DESTROY =~ [Yy] ]]; then

    dropdb -U $VM_USER $PROJECT
    createdb -U $VM_USER $PROJECT

fi

echo
echo Restarting Tomcat...
sudo service tomcat7 start || die "Tomcat startup failed."

echo
echo Rebuild complete.
echo
