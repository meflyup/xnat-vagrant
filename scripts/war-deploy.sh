#!/bin/bash

#
# Download and deploy XNAT war
#

echo Now running the "war-deploy.sh" provisioning script.

sourceScript() {
    test -f /vagrant/scripts/$1 && source /vagrant/scripts/$1 || source /vagrant-root/scripts/$1
}

# Now initialize the build environment from the config's vars.sh settings.
source /vagrant/.work/vars.sh

# look in config's scripts folder first, then try the multi root
sourceScript macros
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
[[ -d /var/lib/tomcat7/webapps/ROOT || -f /var/lib/tomcat7/webapps/ROOT.war ]] && { rm -rf /var/lib/tomcat7/webapps/ROOT*; }


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

# setup XNAT data folders
setupFolders ${DATA_ROOT} ${VM_USER}

# make sure there's a 'universal' local/downloads folder
mkdir -p /vagrant-root/local/downloads
DL_DIR=/vagrant-root/local/downloads

# Download pre-built .war file and copy to tomcat webapps folder
getWar(){

    URL=$1

    cd ${DATA_ROOT}/src

    # if the file has already been downloaded to the host, use that
    if [[ -f ${DL_DIR}/${URL##*/} && ${URL##*/} == *.war ]]; then
        cp ${DL_DIR}/${URL##*/} /var/lib/tomcat7/webapps/ROOT.war
    else
        cd ${DL_DIR}
        echo
        echo "Downloading: ${URL}"
        curl -L --retry 5 --retry-delay 5 -s -O ${URL} \
        && cp ${DL_DIR}/${URL##*/} /var/lib/tomcat7/webapps/ROOT.war \
        || echo "Error downloading '${URL}'"
        cd -
    fi
}

# get the war file and copy it into the webapps folder
echo
echo Getting XNAT war file...
getWar ${XNAT_URL}


getPipeline() {

    URL=$1

    cd ${DATA_ROOT}/src

    [[ ! -d pipeline ]] && { mkdir pipeline; }
    cd pipeline

    # if the file has already been downloaded to the host, use that
    if [[ ! -f ${DL_DIR}/${URL##*/} ]]; then
        cd ${DL_DIR}
        echo
        echo "Downloading: ${URL}"
        curl -L --retry 5 --retry-delay 5 -s -O ${URL} \
        || echo "Error downloading '${URL}'"
        cd -
    fi

    if [[ -f ${DL_DIR}/${URL##*/} ]]; then
        echo Extracting ${URL##*/}...
        unzip -qo ${DL_DIR}/${URL##*/}
        replaceTokens pipeline.gradle.properties | tee gradle.properties
        ./gradlew -q
    fi
}

# Get the pipeline zip file, extract it, and run the installer.
getPipeline ${PIPELINE_URL}

# Is the variable MODULES defined?
[[ -v MODULES ]] \
    && { echo Found MODULES set to ${MODULES}, pulling repositories.; /vagrant-root/scripts/pull_module_repos.rb ${DATA_ROOT}/modules $MODULES; } \
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
startTomcat

monitorTomcatStartup

STATUS=$?
if [[ ${STATUS} == 0 ]]; then
    # after setup is successful, specify 'reload' as the startup command
    printf "reload" > /vagrant/.work/startup
    echo "==========================================================="
    echo "Your VM's IP address is ${VM_IP} and your deployed "
    echo "XNAT server will be available at ${SERVER}."
    echo "==========================================================="
    exit 0;
else
    echo The application does not appear to have started properly. Status code: ${STATUS}
    echo The last lines in the log are:; tail -n 40 /var/log/tomcat7/catalina.out;
fi

exit ${STATUS}

