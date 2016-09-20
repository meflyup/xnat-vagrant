#!/bin/bash

echo Now running the "defaults.sh" provisioning script.

# Set default values for these vars if they're not already set.
[[ -z $DEPLOY ]] && { DEPLOY=release; echo s/@DEPLOY@/release/g >> /vagrant/.work/vars.sed; }
[[ -z $PROJECT ]] && { PROJECT=xnat; echo s/@PROJECT@/xnat/g >> /vagrant/.work/vars.sed; }
[[ -z $SITE ]] && { SITE=XNAT; echo s/@SITE@/XNAT/g >> /vagrant/.work/vars.sed; }
[[ -z $REVISION ]] && { REVISION=1.7.0; echo s/@REVISION@/1.7.0/g >> /vagrant/.work/vars.sed; }
[[ -z $XNAT_REV ]] && { XNAT_REV=$REVISION; echo s/@XNAT_REV@/$REVISION/g >> /vagrant/.work/vars.sed; }
[[ -z $PIPELINE_REV ]] && { PIPELINE_REV=$REVISION; echo s/@PIPELINE_REV@/$REVISION/g >> /vagrant/.work/vars.sed; }
[[ -z $XNAT ]] && { XNAT=xnat-${XNAT_REV}; echo s/@XNAT@/xnat-${XNAT_REV}/g >> /vagrant/.work/vars.sed; }
[[ -z $PIPELINE_INST ]] \
    && { PIPELINE_INST=pipeline-installer-${PIPELINE_REV}; \
    echo s/@PIPELINE_INST@/pipeline-installer-${PIPELINE_REV}/g >> /vagrant/.work/vars.sed; }
