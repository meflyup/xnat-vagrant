#!/bin/bash

cd ../configs

# get list of FOLDER names of configs
listdirs(){ set -- */; printf "%s\n" "${@%/}"; }

# create a fresh 'configs.yaml' file
echo '# configs.yaml' > configs.yaml
echo '# Do not edit this file directly, it will be regenerated when setup is run.' >> configs.yaml

#configs=$(ls -d */)
#configs=$(echo */)
configs=$(listdirs)

for config in ${configs}
do
    config=${config%%/} # chop off the trailing slash
    # if there's an 'alias' file, use that as a shortcut for the name
    [[ -f ${config}/alias ]] && ALIAS=$(<${config}/alias) || ALIAS=${config}
    echo "${ALIAS}: '${PWD}/${config}'" >> configs.yaml;
done