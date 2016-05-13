@echo off

echo.
echo Starting XNAT build...
echo.

echo Provisioning VM with specified user...
vagrant up

echo Reloading VM configuration to configure folder sharing...
vagrant reload

echo Running build provision to build and deploy XNAT on the VM...
vagrant provision --provision-with build

echo Provisioning completed.
