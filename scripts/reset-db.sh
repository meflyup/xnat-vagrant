#!/bin/bash

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

# Reset database?
DESTROY=N
echo
read -p "Are you sure you would like to reset the database? ALL DATABASE DATA IN THIS VM WILL BE DESTROYED. [y/N] " DESTROY

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