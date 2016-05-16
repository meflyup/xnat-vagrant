XNAT Vagrant
==============================

## Setup

- Run ./setup.sh (or setup.bat on Windows) from this folder.
- Go get a beverage.
- Start working with XNAT.

### Notes

- This VM is intended development and trial purposes, and is not designed for
  use in a production environment.
- The default site will be at `http://10.1.1.170`.
- The default login is username: `admin`, password: `admin`
- You can set a hostname using the 'host' property and set a full domain name
  with the 'server' property. These values can be set in a file you create named
  'local.yaml' and they will override the settings in 'config.yaml.'

## Customization

- To customize your configuration, create a file in this folder named 'local.yaml'
  and copy any settings from 'config.yaml' and change them to the desired values.
- Refer to the 'sample.local.yaml' file for example custom settings.

*(to be continued...)*