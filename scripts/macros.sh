#!/bin/bash

echo Now running the "macros.sh" provisioning script.

# cache the *original working directory if not already defined
[[ -z $_OWD ]] && { _OWD=${PWD}; }

# replaceTokens function takes the template name from the first argument to the function call and cats that file out.
# It then replaces all of the tokens with values from vars.sh, then puts the output into the file indicated by the
# second argument to the function.
replaceTokens() {
    cat /vagrant-multi/templates/$1.tmpl | sed -f /vagrant/.work/vars.sed
}

# create default XNAT data folders
setupFolders() {

    DATA_ROOT=$1

    mkdir -p \
        /data \
        ${DATA_ROOT}/src \
        ${DATA_ROOT}/modules/pipeline \
        ${DATA_ROOT}/modules/webapp \
        ${DATA_ROOT}/archive \
        ${DATA_ROOT}/build \
        ${DATA_ROOT}/cache \
        ${DATA_ROOT}/ftp \
        ${DATA_ROOT}/pipeline \
        ${DATA_ROOT}/prearchive \
        ${DATA_ROOT}/scripts


    # Copy some scripts to the scripts folder
    cp /vagrant/.work/vars.sh /data/scripts
    cp /vagrant-multi/scripts/rebuild.sh /data/scripts

}

copyLocalFolder() {
    SRC=$1
    DEST=$2
    echo Copying local folder ${SRC} to ${DEST}
    sudo mkdir -p ${DEST}
    # The `find` here excludes common generated folders in the XNAT builder and pipeline installer folders.
    # It also excludes files and folders that start with the "." character, mainly to exclude the Mercurial metadata.
    sudo find ${SRC} -mindepth 1 -maxdepth 1 \
    ! -name ".[A-z0-9]*" \
    ! -name build \
    ! -name deployments \
    ! -name lib \
    ! -name pipeline \
    ! -name projects \
    ! -name work \
    ! -name "*.log" \
    ! -name "*.[ei]ml" \
    ! -name "build.properties" \
    -exec cp -rf '{}' ${DEST} \;
    status=$?

    # Clear any cached, downloaded, or generated dependencies before doing clean build.
    [[ -d ${DEST}/plugin-resources/cache ]] && { sudo rm -rf ${DEST}/plugin-resources/cache; }
    [[ -d ${DEST}/plugin-resources/repository/nrg ]] && { sudo find ${DEST}/plugin-resources/repository -maxdepth 2 -name jars -exec rm -rf '{}' \;; }

    # Removes above will set to non-0 code if folders not found, we want to use code from find copy.
    return ${status}
}


firstFound=""

# usage:
# findFirst file.txt /path/to/dir1 ./dir2 ./dir3/dir4
# returns first found path (or empty string if not found) as $firstFound var
findFirst() {

    FILENAME=$1

    shift

    # reset $firstFound var
    firstFound=""
	# return if we find it right away
	if [[ -e $FILENAME ]]; then
	    firstFound=$FILENAME
	    return 0
	fi
	# or check the list of directories
	for dir in $@
	do
		if [[ -e $dir/$FILENAME ]]; then
			firstFound=$dir/$FILENAME
			return 0
		fi
		continue
	done
	return 1
}


copyLocal() {

    DIRS=$2

    # set default folders to look in, if not specified
    [[ -z $2 ]] && { DIRS="src local /src /vagrant /vagrant/src /vagrant-multi /vagrant-multi/src"; }

    # look in a few different places
    findFirst $1 ${DIRS}

    if [[ ${firstFound} != "" ]]; then
        SRC=${firstFound}
    else
        return 1
    fi

    # special handling of folders
    if [[ -d ${SRC} ]]; then
        copyLocalFolder ${SRC} ${DATA_ROOT}/src/${SRC##*/}
        copied=$?
    else
        echo Copying ${SRC} into ${DATA_ROOT}/src
        cp -rf ${SRC} ${DATA_ROOT}/src
        copied=$?
    fi

    if [[ $copied == 0 ]]; then
        # if doing a copy, reset permissions
        sudo chown -Rf ${VM_USER}.${VM_USER} /data
    fi

    return $copied

}


uncompress() {

    SRC=$1

    cd ${DATA_ROOT}/src

    if [[ -d ${SRC} ]]; then
        return 0;
    fi

    if [[ ${SRC} == *.tar.gz ]]; then
        echo "Extracting gzip archive..."
        tar -zxf ${SRC}
        #rm ${SRC}
    elif [[ ${SRC} == *.zip ]]; then
        echo "Extracting zip archive..."
        unzip -qo ${SRC}
        #rm ${SRC}
    fi

}


cloneSource() {

    SRC=$1
    choice="x"

    cd $_OWD

    [[ -z $SRC ]] && { SRC="https://bitbucket.org/nrg/xnat_builder_1_7dev"; }

    LOCAL_SRC=local/${SRC##*/}

    SRC_PATH=${PWD}/$LOCAL_SRC

    if [[ -d $LOCAL_SRC ]]; then
        echo
        echo "The '${SRC##*/}' source repo has already been downloaded."
        echo
        echo "Would you like to:"
        echo "  a - clone a fresh copy, DISCARDING ANY LOCAL CHANGES"
        echo "  b - update the existing source with the latest changes from the repo"
        echo "  c - skip and continue"
        echo
        read -p "Enter a, b, or c: " choice
    fi

    [[ $choice == "c" ]] && { return 0; }

    if [[ ! -z $choice && $choice != "c" ]]; then

        if [[ $choice == "a" || $choice == "x" ]]; then

            if [[ -d $LOCAL_SRC ]]; then

                echo
                echo "Are you sure you'd like to DELETE THE LOCAL SOURCE:"
                echo "${SRC_PATH}"
                echo "...and get a fresh copy?"
                read -p "[y/N] " sure
                echo

                if [[ $sure != "y" && $sure != "Y" ]]; then
                    echo "Exiting..."
                    echo ""
                    return 0
                else
                    echo "Deleting existing source directory:"
                    echo "${SRC_PATH}"
                    rm -R $LOCAL_SRC
                fi

            fi

            mkdir -p $LOCAL_SRC

            echo
            echo "Cloning source repo ${SRC}"
            echo "to: ${SRC_PATH}"
            echo

            hg clone -v $SRC $LOCAL_SRC
            cloned=$?

            echo

            [[ $cloned == 0 ]] && { echo "Cloning complete."; } || { echo "An error occurred during cloning."; }

        elif [[ $choice == "b" ]]; then

            cd $LOCAL_SRC

            echo
            echo "Updating local source from ${SRC}"
            echo

            hg pull -u $SRC
            pulled=$?

            echo

            [[ $pulled == 0 ]] && { echo "Update complete."; } || { echo "An error occurred during update."; }

        fi

    else

        echo
        echo "If you'd like to manually clone the source code, create a folder named 'local'"
        echo "and run 'hg clone ${SRC}' from that directory."
        echo
        echo "If you'd like to update an existing repo, run 'hg pull -u' from the source directory."

    fi

}

# Exit with error status
die() {
    echo >&2 "$@"
    exit -1
}
