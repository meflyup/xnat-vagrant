#!/bin/bash

echo Now running the "quick-deploy-templates.sh" provisioning script.

source /vagrant/.work/vars.sh

cd /data/${PROJECT}/src/${XNAT}
bin/quick-deploy-templates.sh
