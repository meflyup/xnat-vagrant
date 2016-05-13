#!/bin/bash

source /vagrant/.work/vars.sh

cd /data/${PROJECT}/src/${XNAT}
bin/quick-deploy-templates.sh
