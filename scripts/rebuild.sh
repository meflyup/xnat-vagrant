#!/bin/bash

# This script is to be executed from inside the VM to rebuild XNAT.
# Gradle will be executed and dependencies downloaded in the VM.

echo Now running the "rebuild.sh" provisioning script.

source vars.sh

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

rm -Rf /var/lib/tomcat7/ROOT*

echo
echo Executing Gradle build

if [[ -e /vagrant/${XNAT_SRC##*/} ]]; then
    cp /vagrant/${XNAT_SRC##*/} /var/lib/tomcat7/ROOT.war
else
    bash -c "${DATA_ROOT}/src/${XNAT_DIR}/gradlew clean war --refresh-dependencies deployToTomcat"
fi

# Reset database?
DESTROY=N
echo
read -p "Would you like to empty the database? All XNAT data will be destroyed. [y/N] " DESTROY

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
