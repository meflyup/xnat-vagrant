XNAT Vagrant
==============================

------------------------------

*\*Disclaimer: this file needs updating - some information may be incorrect.*

# Setup

This XNAT Vagrant project will set up an XNAT 1.7 virtual machine with the required dependencies in a
VirtualBox VM that is suitable for use as a development environment.

You'll need to have [Vagrant](https://www.vagrantup.com), [Git](https://git-scm.com/downloads),
and [VirtualBox](https://www.virtualbox.org) installed on your host machine. You'll also need
[Mercurial](https://mercurial.selenic.com) if you'd like to install the XNAT Pipeline.

If you don't already have a local copy of the XNAT source, you'll need to clone or download it to your
host (local) machine. You can use the XNAT development repo (below) or your own fork or custom repo.

```bash
git clone https://bitbucket.org/xnatdev/xnat-web.git /local/path/to/xnat-web
```

If you want the XNAT Pipeline installed, you'll need to clone that as well:

```bash
git clone https://bitbucket.org/nrg/xnat-pipeline.git /local/path/to/xnat-pipeline
```

Next you'll need to clone the **`xnat-vagrant`** repo (this one) and navigate to that folder:

```bash
git https://github.com/NrgXnat/xnat-vagrant
```

In this folder, create a file named `local.yaml` with **`xnat_src`** and **`pipeline_src`** parameters containing
the paths to your local source code (you may want to duplicate the `sample.local.yaml` file and rename it
to `local.yaml` as a starting point):

```
xnat_src:     '/local/path/to/xnat-web'
pipeline_src: '/local/path/to/xnat-pipeline'
```

> You **MUST** specify the `xnat_src` (and optionally `pipeline_src`) parameters before continuing or setup will fail.

Launch the `setup.sh` script (or `setup.bat` on Windows):

```bash
./setup.sh
```

> The setup script automates the process of creating the Vagrant VM and configuring it for development.

You can do the setup manually with the following commands:

```bash
vagrant up
vagrant reload
vagrant provision --provision-with build
```

> This will create a Vagrant VM with XNAT built from the [xnat-web](https://bitbucket.org/xnatdev/xnat-web)
> repo using default settings in the `'config.yaml'` for the config you're building, using the source code
> specified in your `'local.yaml'` file. If you'd like to further customize your installaion,
> you may set custom values in your `'local.yaml'` file for properties in `'config.yaml'`.

After setup is complete, log in to your XNAT site:

```
http://10.0.0.170
username: admin
password: admin
```

If you'd like to access the XNAT VM via SSH, run this command from the `'xnat_vagrant'` folder

```bash
vagrant ssh
```

Then switch to the VM user (**`xnat`** in this case) after you're logged in:

```bash
sudo su - xnat
```

After your VM is provisioned, you will need to build your XNAT webapp with Gradle. The README file in the
['xnat-web' repo](https://bitbucket.org/xnatdev/xnat-web) should help with that. The simplest (but slowest)
way to do the Gradle build is from *inside* the VM. To do this, log into the VM with `vagrant ssh` and
run these commands (in this case, 'xnat' is both the `project` and `xnat_src` value):

```bash
cd /data/xnat/src/xnat
./gradlew war deployToTomcat
```

After the setup and build steps are completed, log in to your XNAT site:

```
http://10.1.7.170
username: admin
password: admin
```

> **Note:** After initial setup, just run **`vagrant reload`** from your Vagrant folder to launch your XNAT VM.

------------------------------

# The Details

The XNAT Vagrant project provisions an Ubuntu 14.04-based virtual machine with XNAT and all
supporting requirements, including:

* Tomcat
* nginx
* PostgreSQL
* OpenJDK 7/8

> The latest version of this document and the XNAT Vagrant project can be found on the
> [XNAT Vagrant Repository](https://github.com/NrgXnat/xnat-vagrant).

## Prerequisites

To create an XNAT virtual machine with the XNAT Vagrant project, you'll need the following software:

* [Git](https://git-scm.com/downloads)
* [Mercurial](https://mercurial.selenic.com)
* [Vagrant](https://www.vagrantup.com)
* [VirtualBox](https://www.virtualbox.org)

You can use [VMWare](http://www.vmware.com) products, such as Workstation or Fusion, instead of VirtualBox,
but these require a [special VirtualBox VMWare plugin](https://www.vagrantup.com/vmware).

The default configuration for the XNAT Vagrant project creates an instance of XNAT 1.7 accessible at
`http://10.0.0.170`. See the **Project Configuration** section below for information on how to change the URL
to use a FQDN and other attributes of the generated virtual machine. See the **Host Configuration** section
below for information on how to set up your host machine to access the XNAT instance by URL in your browser.

> Note that this formula creates a server VM instance without a desktop environment. The VM is created using
Ubuntu 15.04 as the base. There are a number of desktop environments that can be installed on top of this
server system using the **`apt-get`** installation tool.

Once your virtual machine is up and running, you can access it via **ssh**:

```bash
vagrant ssh
sudo su - xnat
```

If you'd like to access your VM via SSH or SFTP directly as the **`[vm_user]`**, you'll need to set a password for that user after logging in using `vagrant ssh`. For example, if your **`[vm_user]`** was **`xnat`**:

```bash
sudo passwd xnat
```

Then enter your desired password when prompted.

Once logged into the VM through SSH or SFTP, you can find various resources on the VM:

The builder and pipeline installer folders are located in **`/data/[project]/src`**.

* XNAT Builder: **`/data/[project]/src/xnat`**
* Pipeline: **`/data/[project]/src/pipeline`**

The XNAT application is deployed into Tomcat 7 **`/var/lib/tomcat7/webapps/[project]`**.

* Log files are in the **`logs`** subfolder.
* Configuration files are in the **`WEB-INF/conf`** subfolder.

Modules can be placed into **`/data/[project]/modules`**.

* Web app modules go in the **`webapp`** subfolder
* Pipeline modules go in the **`pipeline`** folder.


## Project Configuration

This Vagrant project uses YAML files to set the various properties that drive the VM's configuration. The default values are set in the file **`default.yaml`** and may be updated periodically to set the default configuration to use the latest revision of XNAT, change the version of Java, and the like.

Here are the settings specified in the configuration file:

* **`name`** is the VirtualBox inventory name of the VM to be created. The default is **`xnatdev`**.
* **`host`** (optional) is the hostname for the VM. Use only letters, numbers, hyphens, and periods. (will use **`[name]`** if empty)
* **`server`** is the _complete_ FQDN (or the IP address set in **`[vm_ip]`**) for the server. Use only letters, numbers, hyphens, and periods. The default is **`10.0.0.165`** (as set in **`[vm_ip]`**).
* **`site`** is the site title. The default is **`XNAT`**.
* **`admin`** (optional) is the full email address of the site administrator. (will use **`admin@[server]`** if not specified)
* **`project`** is the project name for the XNAT application. The default is **`xnat`**.
* **`xnat_src`** is the file/folder name or url of the XNAT source code. The provisioning script will first search for a file/folder name locally, and if a match is found, it will be used for the XNAT source, otherwise the script will attempt to download the source via FTP or clone via Mercurial. The default is **`xnat-1.6.5.tar.gz`** and will be download via FTP if not available locally.
* **`xnat_rev`** is the revision of XNAT to retrieve. If **`deploy`** is set to `release`, the bundle downloaded from the FTP server is **`xnat-[version]`**. If **`deploy`** is set to `dev`, the `release` value is used as the revision (tag or changeset) when the repository is cloned. The default is **`1.6.5`**.
* **`pipeline_src`** is the name file or folder name of the pipeline installer. The default is **`pipeline-installer-1.6.5.tar.gz`** and will be downloaded via FTP if not available locally.
* **`pipeline_rev`** is the revision of the pipeline code you will use.
* **`box`** is the name of the box that Vagrant will use.
* **`box_url`** is the url for the box that Vagrant will download if it hasn't been downloaded yet.
* **`java_path`** is the path to the installed Java development kit on the created guest VM.
* **`vm_user`** (optional) is the username on the VM for running XNAT. (defaults to **`[project]`**)
* **`vm_ip`** sets the private network IP for your VM. The default is **`10.0.0.165`**.
* **`ram`** is the amount of RAM to be allocated for your VM. The default is **`2048`**.
* **`cpus`** sets the number of CPU core to allocate to the VM. The default is **`1`**.
* **`gui`** indicates whether the VM should be created in a headless state or have an associated terminal. The default is **`false`**. Note that this does not mean that a GUI desktop like Gnome or KDE is installed. You can get a desktop installed by changing the Vagrant box to something like **`boxcutter/ubuntu1404-desktop`** or by installing the appropriate packages on the server after the Vagrant provisioning process completes.
* **`shares`** (optional) map of paths to local folders you'd like to share into your VM.
* **`provision`** (optional) name of Vagrant provisioning script. (will use **`provision.sh`** if not specified)

## Host Configuration

The VM built by Vagrant can be configured with a fully-qualified domain name (FQDN) that can be set in the configuration YAML. For example, using the default configuration settings, your VM will be accessible at the IP address specified in **`[vm_ip]`**, but if you'd like to access your XNAT site by domain name, you can set the **`[server]`** property to the FQDN (like **`xnat.dev`**) you'd like to use. The FQDN will be mapped to the **`[vm_ip]`** in the VM's **`/etc/hosts`** file. In order to reach the VM using this address, you'll need to add the server-to-IP mapping in your host machine's **`hosts`** file. For OS X and Linux machines, this just means adding the following line to your local **`/etc/hosts`** file:

```
10.0.0.170  xnatdev xnat.dev
```

On Windows, if you specify a FQDN for **`[server]`**, you will also need to modify the **`hosts`** file, but it's a bit more involved. [This page](http://bit.ly/modhosts) describes the process for most OSes, including Windows.

## Customization

> NOTE: Customizations are read from the `local.yaml` file

### local.yaml
> NOTE: support for reading custom settings from `custom.yaml` files is no longer supported - it was
> redundant with `local.yaml`, so use `local.yaml` instead.

You can override specific default settings by creating a file named **`custom.yaml`** that contains ONLY those parameters you wish to override.

For example, if you wanted to set custom **`[name]`**, **`[admin]`**, and **`[vm_ip]`** values, you would put the following lines into a **`custom.yaml`** file.

```
# local.yaml

name:       'xnatcustom'
admin:      'admin@yourdomain.org'
vm_ip:      '10.1.7.0'
```

All other settings will be inherited from the `default.yaml` file and any configuration file
specified in the **`[config]`** property.


## Accessing the XNAT Application

Once your XNAT Vagrant instance is up and running, XNAT should be available at the FQDN indicated in the configuration YAML. Just enter that into your browser address bar.

The default login credentials for your new XNAT site are:

* **Username:** admin
* **Password:** admin