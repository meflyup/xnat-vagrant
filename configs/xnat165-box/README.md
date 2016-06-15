XNAT 1.6.5 Pre-built Vagrant Box
================================

## About the 'xnat165-box' config

This config will download and run a pre-built XNAT 1.6.5 Vagrant box. The version of XNAT running in this box is
the 1.6.5 release, extracted from the official release archive that can be downloaded at
[ftp://ftp.nrg.wustl.edu/pub/xnat/xnat-1.6.5.tar.gz](ftp://ftp.nrg.wustl.edu/pub/xnat/xnat-1.6.5.tar.gz). The XNAT
pipeline is also installed using source from
[ftp://ftp.nrg.wustl.edu/pub/xnat/pipeline-installer-1.6.5.tar.gz](ftp://ftp.nrg.wustl.edu/pub/xnat/pipeline-installer-1.6.5.tar.gz).

To run this VM, simply run `vagrant up` from this directory or `./run xnat165-box start` from this repo's 'root'
directory. The 'setup' scripts are included, but they just perform a `vagrant up` command since this box is pre-built
and there is no setup needed.

```bash
vagrant up
```

To access the pre-configured site, go to `http://10.1.1.165` and log in with username 'admin' and password 'admin'.
If you get an error stating the site can't be reached, you may need to manually add the port number `:8080` to the
site url in your browser - `http://10.1.1.165:8080` - and refresh the page. To prevent this error in the future, add the
port number `:8080` to the **Site URL** setting (the full URL will be `http://10.1.1.165:8080`) and save the changes.

The VM has been set up with a local user named 'xnat' and you can change this user's password after logging in
with the `vagrant ssh` command (make sure you run the command from this config's directory):

```bash
vagrant ssh
```

After logging into the VM, use the `passwd` command to set the password for the 'xnat' user.

```bash
sudo passwd xnat
```

Enter the desired password when promted then exit from the VM.

```bash
exit
```

You should now be able to log in to the VM via SSH or SFTP as the 'xnat' user (using the new password) at `10.1.1.165`.

```bash
ssh xnat@10.1.1.165
```

## Doing development with this VM

In the VM, the paths to the XNAT and Pipeline source code are, respectively:

- `/data/xnat/src/xnat`
- `/data/xnat/src/pipeline-installer`


You can modify the source there (or copy modified files via SCP or SFTP) then run the `setup.sh`, `update.sh`, or
`quick-deploy*.sh` scripts to push your changes to the running web app at `/var/lib/tomcat7/webapps/xnat`. If you're
doing front-end work, you can make changes to front-end code (Velocity templates, JavaScript, CSS, images, etc.)
directly in the web app and see your changes instantly (after refreshing the page, of course).

## Note

Since this box is pre-built, the initial configuration cannot be changed. The IP address can be changed in the
config.yaml file, but if it does not match the IP address that the running XNAT expects (10.1.1.165), you will not be
able to use the site. If you want to change the IP address, do so first in the running XNAT site, then set a
matching value for the 'vm_ip' property in a 'local.yaml' file and restart the VM.