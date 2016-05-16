#!/bin/bash
#
# XNAT download and installation
#

echo Now running the "gradle-build=prev.sh" provisioning script.

source /vagrant/.work/vars.sh
source /vagrant/scripts/macros.sh
source /vagrant/scripts/defaults.sh
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
if [ -d /data/${PROJECT} ]; then
    echo Using existing folder /data/${PROJECT}, setting ownership to ${VM_USER}
    sudo chown ${VM_USER}.${VM_USER} /data
    sudo chown ${VM_USER}.${VM_USER} /data/${PROJECT}
    if [ -d /data/${PROJECT}/src ]; then
        sudo chown ${VM_USER}.${VM_USER} /data/${PROJECT}/src
    fi
else
    echo Creating folder /data/${PROJECT}
    sudo mkdir -p /data/${PROJECT};
    sudo chown -R ${VM_USER}.${VM_USER} /data
fi

mkdir -p \
    /data/${PROJECT}/src \
    /data/${PROJECT}/modules/pipeline \
    /data/${PROJECT}/modules/webapp \
    /data/${PROJECT}/archive \
    /data/${PROJECT}/build \
    /data/${PROJECT}/cache \
    /data/${PROJECT}/ftp \
    /data/${PROJECT}/prearchive

# Copies or downloads specified release archive or folder
getRelease() {

    SRC=$1

    cd /data/${PROJECT}/src
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
    if [[ -e /data/${PROJECT}/src/${DIR} ]]; then
        copied=0
    # clone with Git if SRC ends with .git
    elif [[ ${SRC} == *.git ]]; then
        echo "Cloning source repository: ${SRC}"
        git clone ${SRC} /data/${PROJECT}/src/${DIR}
        copied=$?
    elif [[ ${SRC} == ftp* ]]; then
        # use getRelease for ftp
        getRelease ${SRC}
        copied=$?
    elif [[ ${SRC} == http* || ${SRC} == ssh* || ${SRC} == file:* ]]; then
        # clone with Mercurial for http, ssh, and file protocols
        echo "Cloning source repository: ${SRC}"
        hg -v clone ${SRC} -r ${REV} /data/${PROJECT}/src/${DIR} || hg -v clone ${SRC} /data/${PROJECT}/src/${DIR}
        copied=$?
    fi

    if [[ $copied != 0 ]]; then
        copyLocal ${SRC} /data/${PROJECT}/src/${DIR}
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
[[ -d /data/${PROJECT}/src/xnat ]] && { XNAT_DIR="xnat"; }
if [[ -d /data/${PROJECT}/src/${XNAT_DIR} && ! -d /data/${PROJECT}/src/${XNAT} ]]; then
    mv -v /data/${PROJECT}/src/${XNAT_DIR} /data/${PROJECT}/src/${XNAT}
fi
# move pipeline source to properly named folder
[[ -d /data/${PROJECT}/src/pipeline-installer ]] && { PIPE_DIR="pipeline-installer"; }
if [[ -d /data/${PROJECT}/src/${PIPE_DIR} && ! -d /data/${PROJECT}/src/${PIPELINE_INST} ]]; then
    mv -v /data/${PROJECT}/src/${PIPE_DIR} /data/${PROJECT}/src/${PIPELINE_INST}
fi

# Is the variable MODULES defined?
[[ -v MODULES ]] \
    && { echo Found MODULES set to ${MODULES}, pulling repositories.; /vagrant/scripts/pull_module_repos.rb /data/${PROJECT}/modules $MODULES; } \
    || { echo No value set for the MODULES configuration, no custom functionality will be included.; }

mkdir -p ~/${PROJECT}/config
replaceTokens services.properties | tee /data/${PROJECT}/src/${XNAT}/src/main/webapp/WEB-INF/conf/services.properties | tee ~/${PROJECT}/config/services.properties

# Now run the setup.
# bin/setup.sh -Ddeploy=true 2>&1 | tee setup.log
replaceTokens InstanceSettings.xml | tee /data/${PROJECT}/src/${XNAT}/src/main/webapp/WEB-INF/conf/InstanceSettings.xml

# Gradle deployment setup
timestamp=$(date +%s);
mkdir -p ~/.gradle
[[ -e ~/.gradle/gradle.properties ]] && { mv ~/.gradle/gradle.properties ~/.gradle/gradle-${timestamp}.properties; }
echo '# ~/.gradle/gradle.properties' > ~/.gradle/gradle.properties
echo archiveName=ROOT >> ~/.gradle/gradle.properties
echo tomcatHome=/var/lib/tomcat7 >> ~/.gradle/gradle.properties

# Move the default ROOT out of the way
if [ -d /var/lib/tomcat7/webapps/ROOT ]; then
    mv /var/lib/tomcat7/webapps/ROOT /var/lib/tomcat7/webapps/default
fi

# Search for any post-build execution folders and execute the install.sh
for POST_DIR in /vagrant/post_*; do
    if [[ -e ${POST_DIR}/install.sh ]]; then
        echo Executing post-processing script ${POST_DIR}/install.sh
        bash ${POST_DIR}/install.sh
    fi
done

sudo rm -rf /var/log/tomcat7/*

# optionally run the Gradle build inside the VM
if [[ ! -z ${DEPLOY} && ${DEPLOY} == 'gradle-vm' ]]; then
    echo "Starting Gradle build..."
    cd /data/${PROJECT}/src/${XNAT}
    ./gradlew war deployToTomcat && echo "Gradle build complete." || die "Gradle build failed."
fi

echo "Starting Tomcat..."
sudo service tomcat7 start || die "Tomcat startup failed."

echo "==================================================="
echo "Your VM's IP address is ${VM_IP} and your deployed "
echo "XNAT server will be available at ${SERVER}."
echo "==================================================="
