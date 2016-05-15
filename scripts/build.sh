#!/bin/bash
#
# XNAT download and installation
#

SOURCE=$(basename -- ${BASH_SOURCE[0]})
echo Now running the "${SOURCE}" provisioning script.

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
echo -e "${VM_IP}\t${HOST} ${SERVER}" | sudo tee --append /etc/hosts

# Configure nginx to proxy Tomcat.
replaceTokens xnatdev | sudo tee /etc/nginx/sites-available/${HOST}
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/${HOST} /etc/nginx/sites-enabled/${HOST}

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

# Copies or downloads specified release archive or folder
getRelease() {

    SRC=$1

    cd ${DATA_ROOT}/src
    # tolerate complete URLs for [xnat_src] and [pipeline_src]
    [[ ${SRC} != ftp://* ]] && { SRC=ftp://ftp.nrg.wustl.edu/pub/xnat/${SRC}; }
    echo "Downloading: ${SRC}"
    wget -N -nv ${SRC} || echo "Error downloading '${SRC}'"

}

# clone dev source repo or copy a repo (folder) already downloaded locally
getDev() {

    SRC=$1
    REV=$2
    DIR=$3
    copied=1

    # check to see if the src dir already exists
    if [[ -e ${DATA_ROOT}/src/${DIR} ]]; then
        copied=0
    # clone with Git if SRC ends with .git
    elif [[ ${SRC} == *.git ]]; then
        echo "Cloning source repository: ${SRC}"
        git clone ${SRC} ${DATA_ROOT}/src/${DIR}
        copied=$?
    elif [[ ${SRC} == ftp* ]]; then
        # use getRelease for ftp
        getRelease ${SRC}
        copied=$?
    elif [[ ${SRC} == http* || ${SRC} == ssh* || ${SRC} == file:* ]]; then
        # clone with Mercurial for http, ssh, and file protocols
        echo "Cloning source repository: ${SRC}"
        hg -v clone ${SRC} -r ${REV} ${DATA_ROOT}/src/${DIR} || hg -v clone ${SRC} ${DATA_ROOT}/src/${DIR}
        copied=$?
    fi

    if [[ $copied != 0 ]]; then
        copyLocal ${SRC} ${DATA_ROOT}/src/${DIR}
        copied=$?
        if [[ $copied != 0 ]]; then
            echo "Copy failed."
            exit;
        fi
    fi

    # in case the 'dev' source is an archive of the repo
    uncompress ${SRC##*/};

}

# get dev or release files
getDev ${XNAT_SRC} ${XNAT_REV} ${XNAT};
getDev ${PIPELINE_SRC} ${PIPELINE_REV} ${PIPELINE_INST};

# hacky conversion of _SRC to _DIR to handle differences
# between the _SRC parameter and the actual folder name
XNAT_DIR=${XNAT_SRC##*/}; XNAT_DIR=${XNAT_DIR%.tar.gz}; XNAT_DIR=${XNAT_DIR%.zip};
PIPE_DIR=${PIPELINE_SRC##*/}; PIPE_DIR=${PIPE_DIR%.tar.gz}; PIPE_DIR=${PIPE_DIR%.zip};

# move xnat source to properly named folder
[[ -d ${DATA_ROOT}/src/xnat ]] && { XNAT_DIR="xnat"; }
if [[ -d ${DATA_ROOT}/src/${XNAT_DIR} && ! -d ${DATA_ROOT}/src/${XNAT} ]]; then
    mv -v ${DATA_ROOT}/src/${XNAT_DIR} ${DATA_ROOT}/src/${XNAT}
fi
# move pipeline source to properly named folder and build it.
[[ -d ${DATA_ROOT}/src/pipeline-installer ]] && { PIPE_DIR="pipeline-installer"; }
if [[ -d ${DATA_ROOT}/src/${PIPE_DIR} && ! -d ${DATA_ROOT}/src/${PIPELINE_INST} ]]; then
    mv -v ${DATA_ROOT}/src/${PIPE_DIR} ${DATA_ROOT}/src/${PIPELINE_INST}
    replaceTokens pipeline.gradle.properties | tee ${DATA_ROOT}/src/${PIPELINE_INST}/gradle.properties
    pushd ${DATA_ROOT}/src/${PIPELINE_INST}
    ./gradlew
    popd
fi

replaceTokens build.properties | tee ${DATA_ROOT}/src/${XNAT}/build.properties

# Make XNAT user the Tomcat owner.
sudo chown -RL ${VM_USER}.${VM_USER} /var/lib/tomcat7
sudo chown -Rh ${VM_USER}.${VM_USER} /var/lib/tomcat7

# Set up the server.xml, context.xml, and tomcat7 configuration files.
cp /var/lib/tomcat7/conf/server.xml /var/lib/tomcat7/conf/server.xml.bak
cp /var/lib/tomcat7/conf/context.xml /var/lib/tomcat7/conf/context.xml.bak
sudo cp /etc/default/tomcat7 /etc/default/tomcat7.bak
replaceTokens server.xml | tee /var/lib/tomcat7/conf/server.xml
replaceTokens tomcat7 | sudo tee /etc/default/tomcat7
# This just removes the comments around the <Manager pathname=""/> element. Having that active prevents Tomcat from
# trying to restore serialized sessions across restarts.
tac /var/lib/tomcat7/conf/context.xml | sed '/Manager pathname/{N;s/\n.*//;}' | tac | sed '/Manager pathname/{N;s/\n.*//;}' > /var/lib/tomcat7/conf/context.mod
mv /var/lib/tomcat7/conf/context.mod /var/lib/tomcat7/conf/context.xml
mkdir /var/lib/tomcat7/empty

# Create XNAT's database user.
sudo -u postgres createuser -U postgres -S -d -R ${VM_USER}
sudo -u postgres psql -U postgres -c "ALTER USER ${VM_USER} WITH PASSWORD '${VM_USER}'"
sudo -u postgres createdb -U postgres -O ${VM_USER} ${PROJECT}

# Modify the PostgreSQL settings to allow connections from outside the VM.
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/${DB_VERSION}/main/postgresql.conf
sudo cp /etc/postgresql/${DB_VERSION}/main/pg_hba.conf /etc/postgresql/${DB_VERSION}/main/pg_hba.conf.bak
replaceTokens pg_hba.conf | sudo tee -a /etc/postgresql/${DB_VERSION}/main/pg_hba.conf
sudo service postgresql restart

# Is the variable MODULES defined?
[[ -v MODULES ]] \
    && { echo Found MODULES set to ${MODULES}, pulling repositories.; /vagrant-multi/scripts/pull_module_repos.rb ${DATA_ROOT}/modules $MODULES; } \
    || { echo No value set for the MODULES configuration, no custom functionality will be included.; }

# xnat installation
cd ${DATA_ROOT}/src/${XNAT}
FOLDERS=("deployments" "projects" "plugin-resources/cache" "work" "lib" "bin/[A-Z]*")
for FOLDER in "${FOLDERS[@]}"; do
    if [[ -d ${FOLDER} ]]; then
        rm -rf ${FOLDER}
    fi
done

# Now run the setup.
bin/setup.sh -Ddeploy=true 2>&1 | tee setup.log

# You only run the database scripts and StoreXML initialization for XNAT 1.6.x. 1.7 and later does initialization on server start-up.
if [[ ${REVISION} == 1.6* ]]; then
    cd ${DATA_ROOT}/src/${XNAT}/deployments/${PROJECT}
    psql -d ${PROJECT} -f sql/${PROJECT}.sql
    StoreXML -l security/security.xml -allowDataDeletion true
    StoreXML -dir ./work/field_groups -u admin -p admin -allowDataDeletion true
else
    mkdir -p ~/config
    cp ${DATA_ROOT}/src/${XNAT}/deployments/${PROJECT}/conf/services.properties ~/config
fi

# Search for any post-build execution folders and execute the install.sh
for POST_DIR in /vagrant-multi/post_*; do
    if [[ -e ${POST_DIR}/install.sh ]]; then
        echo Executing post-processing script ${POST_DIR}/install.sh
        bash ${POST_DIR}/install.sh
    fi
done

sudo rm -rf /var/log/nginx/* /var/log/tomcat7/*

echo "Starting nginx..."
sudo service nginx start

echo "Starting Tomcat..."
sudo service tomcat7 start

tomcatStatus=$?

echo "================================================================================"

if [[ ${tomcatStatus} == 0 ]]; then
    echo "Provisioning Completed"
    echo "The XNAT Vagrant installation scripts have completed. You can log into your new XNAT VM instance"
    echo "by typing 'vagrant ssh'. You may want to update the software on your VM to the latest version. To"
    echo "do this, login and type:"
    echo
    echo "  sudo apt-get update"
    echo "  sudo apt-get -y dist-upgrade"
    echo
    echo "You may log in to the newly configured XNAT server at http://${SERVER} with the username 'admin'"
    echo "and password 'admin' to begin using XNAT."
    echo
    echo "Thanks for using XNAT!"
else
    echo "Provisioning failed."
fi

echo "================================================================================"
