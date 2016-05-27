#!/bin/bash

CONFIG=xnat

# Exit with error status
die() {
    echo >&2 "$@"
    exit -1
}

mkdir -p .work
if [[ ! -z $1 ]]; then
    CONFIG=$1
fi

printf ${CONFIG} > .work/config

echo
echo "Starting XNAT build using '${CONFIG}' config..."

# run the setup scripts and Vagrant commands from the config folder
[[ ! -d ./configs/${CONFIG} ]] && die "Configuration not found."

cd ./configs/${CONFIG}

bash ./setup.sh
