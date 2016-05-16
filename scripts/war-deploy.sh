#!/bin/bash

#
# Download and deploy XNAT war
#

echo Now running the "war-deploy.sh" provisioning script.

sourceScript() {
    test -f /vagrant/scripts/$1 && source /vagrant/scripts/$1 || source /vagrant-multi/scripts/$1
}

# Now initialize the build environment from the config's vars.sh settings.
source /vagrant/.work/vars.sh

# look in config's scripts folder first, then try the multi root
sourceScript macros.sh
sourceScript defaults.sh

source ~/.bash_profile

# Stop these services so that we can configure them later.
sudo service tomcat7 stop
sudo service nginx stop

# Configure the host settings.
echo -e "${VM_IP} ${HOST} ${SERVER}" | sudo tee --append /etc/hosts

# Configure nginx to proxy Tomcat.
replaceTokens xnatdev | sudo tee /etc/nginx/sites-available/${HOST}
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/${HOST} /etc/nginx/sites-enabled/${HOST}

sudo rm -rf /var/log/nginx/*

echo "Starting nginx..."
sudo service nginx start

# TOMCAT STUFF
sudo chown -RL ${VM_USER}.${VM_USER} /var/lib/tomcat7
sudo chown -Rh ${VM_USER}.${VM_USER} /var/lib/tomcat7

# Set up the server.xml, context.xml, and tomcat7 configuration files.
cp /var/lib/tomcat7/conf/context.xml /var/lib/tomcat7/conf/context.xml.bak
sudo cp /etc/default/tomcat7 /etc/default/tomcat7.bak
replaceTokens tomcat7 | sudo tee /etc/default/tomcat7

# This just removes the comments around the <Manager pathname=""/> element. Having that active prevents Tomcat from
# trying to restore serialized sessions across restarts.
tac /var/lib/tomcat7/conf/context.xml | sed '/Manager pathname/{N;s/\n.*//;}' | tac | sed '/Manager pathname/{N;s/\n.*//;}' > /var/lib/tomcat7/conf/context.mod
mv /var/lib/tomcat7/conf/context.mod /var/lib/tomcat7/conf/context.xml
replaceTokens tomcat-users.xml | tee /var/lib/tomcat7/conf/tomcat-users.xml

# Move the default ROOT folder out of the way
if [ -d /var/lib/tomcat7/webapps/ROOT ]; then
    mv /var/lib/tomcat7/webapps/ROOT /var/lib/tomcat7/webapps/default
fi


# POSTGRES STUFF
echo "Setting up postgres"
# Create XNAT's database user.
sudo -u postgres createuser -U postgres -S -d -R ${VM_USER}
sudo -u postgres psql -U postgres -c "ALTER USER ${VM_USER} WITH PASSWORD '${VM_USER}'"
sudo -u postgres createdb -U postgres -O ${VM_USER} ${PROJECT}

# Modify the PostgreSQL settings to allow connections from outside the VM.
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/${DB_VERSION}/main/postgresql.conf
sudo cp /etc/postgresql/${DB_VERSION}/main/pg_hba.conf /etc/postgresql/${DB_VERSION}/main/pg_hba.conf.bak
replaceTokens pg_hba.conf | sudo tee -a /etc/postgresql/${DB_VERSION}/main/pg_hba.conf
sudo service postgresql restart


# XNAT STUFF

# Create project subfolders
if [ -d ${DATA_ROOT} ]; then
    echo Using existing folder ${DATA_ROOT}, setting ownership to ${VM_USER}
    sudo chown ${VM_USER}.${VM_USER} /data
    sudo chown ${VM_USER}.${VM_USER} ${DATA_ROOT}
    if [ -d ${DATA_ROOT}/src ]; then
        sudo chown ${VM_USER}.${VM_USER} ${DATA_ROOT}/src
    fi
else
    echo Creating folder ${DATA_ROOT}
    sudo mkdir -p ${DATA_ROOT};
    sudo chown -R ${VM_USER}.${VM_USER} /data
fi

# setup XNAT data folders
setupFolders ${DATA_ROOT}

# Download pre-built .war file and copy to tomcat webapps folder
getWar(){

    URL=$1

    cd ${DATA_ROOT}/src

    # if the file has already been downloaded to the host, use that
    if [[ -f /vagrant/${URL##*/} ]]; then
        cp /vagrant/${URL##*/} /var/lib/tomcat7/webapps/ROOT.war
    else
        echo
        echo "Downloading: ${URL}"
        curl -s -o /vagrant/${URL##*/} ${URL} \
        && cp /vagrant/${URL##*/} /var/lib/tomcat7/webapps/ROOT.war \
        || echo "Error downloading '${URL}'"
    fi
}

# get the war file and copy it into the webapps folder
echo
echo Getting XNAT war file...
getWar ${XNAT_URL}


# TODO: pipeline download and processing
getPipeline() {

    URL=$1

    cd ${DATA_ROOT}/src

    [[ ! -d pipeline ]] && { mkdir pipeline; }
    cd pipeline

    # if the file has already been downloaded to the host, use that
    if [[ ! -f /vagrant/${URL##*/} ]]; then
        echo
        echo "Downloading: ${URL}"
        curl -s -o /vagrant/${URL##*/} ${URL} \
        || echo "Error downloading '${URL}'"
    fi

    if [[ -f /vagrant/${URL##*/} ]]; then
        unzip /vagrant/${URL##*/}
        replaceTokens pipeline.gradle.properties | tee gradle.properties
        ./gradlew
    fi
}

# Get the pipeline zip file, extract it, and run the installer.
getPipeline ${PIPELINE_URL}

# Is the variable MODULES defined?
[[ -v MODULES ]] \
    && { echo Found MODULES set to ${MODULES}, pulling repositories.; /vagrant-multi/scripts/pull_module_repos.rb ${DATA_ROOT}/modules $MODULES; } \
    || { echo No value set for the MODULES configuration, no custom functionality will be included.; }

mkdir -p ${HOME}/config
mkdir -p ${HOME}/logs
mkdir -p ${HOME}/plugins
mkdir -p ${HOME}/work

replaceTokens xnat-conf.properties | tee ${HOME}/config/xnat-conf.properties

# Search for any post-build execution folders and execute the install.sh
for POST_DIR in /vagrant/post_*; do
    if [[ -e ${POST_DIR}/install.sh ]]; then
        echo Executing post-processing script ${POST_DIR}/install.sh
        bash ${POST_DIR}/install.sh
    fi
done

sudo rm -rf /var/log/tomcat7/*

echo "Starting Tomcat..."
sudo service tomcat7 start || die "Tomcat startup failed."

echo "================================================================"
echo "Your VM's IP address is ${VM_IP} and your deployed "
echo "XNAT server will be available at http://${SERVER}."
echo "================================================================"
