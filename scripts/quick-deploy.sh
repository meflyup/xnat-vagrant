#!/bin/bash

source /vagrant/.work/vars.sh

cd /data/${PROJECT}/src/${XNAT}
bin/quick-deploy.sh -Dclass.dir=ide-bin && sudo service tomcat7 restart
