shconfig
===

The purpose of this project is to configure a server using shell scripts and variable substitution.

# How to use this project

Consider creating your own repository based on this code, where you can then update and control everything in `src/`. Search for the string `FIXME` to find common areas to update.

Additionally, this project was designed so that you don't have to be root to run it in a production environment. You will get warnings about things that require elevated permissions.

# Common tasks

## web server deployments:

    ssh username@webhost
	cd /data/shconfig
	SKIP_LASTPASS=1 DEBUG=1 ./driver.sh

## database server deployments:

    ssh username@dbhost
	cd /data/shconfig
	SKIP_LASTPASS=1 DEBUG=1 ./driver.sh

## common options to driver.sh:

* `SKIP_LASTPASS=1`: does not ask you for your LastPass credentials; doesn't update `vars/secrets.json`.
* `DEBUG=1`: prints out much more information.
* `FORCE_UPDATE=1`: will rebuild and redeploy git repos even if there aren't any changes.

# Development quick start

1. Install Oracle VirtualBox. If you have never done this before, you may also have to change your computer's BIOS settings to allow virtualization.

2. Install Vagrant including NFS support.

	- For OS X this means:

		- Install Vagrant
		- In System Preferences -> Security -> Privacy, give "/sbin/nfsd" `Full Disk Access`

     _Note: as of Dec 2019, Vagrant on OS X does not properly escape the NFS mountpoints on the host machine if the mountpoints have spaces in them. You may be able to fix this by editing /etc/exports manually, or by changing your directory to one that doesn't have spaces in it._

	- For Windows this means:

	    - Install Vagrant
	    - Install vagrant-winnfsd via vagrant plugin install vagrant-winnfsd
        - Give your Windows account access to create symlinks. On Windows 10 you do this via
            - Run "Edit Group Policy" as administrator
		    - Go to Computer Configuration > Windows Settings > Security Settings > Local Policies > User Rights Assignment
		    - Add your user to the "Create symbolic links" permission
		    - Log out and back in so you have the permission
  
    - _Note: as of 2021, Vagrant's "vagrant-vbguest" plugin is not compatible with the CentOS 7 image we use. Please uninstall this plugin via `vagrant plugin uninstall vagrant-vbguest` if it is installed (or figure out how to fix this!)._
    - _Note: if SSH isn't working, you may need to specify the SSH client manually._
    - _Note: if NFS isn't working (as evidenced by `cd /vagrant_data` hanging), you may need to specify `config.winnfsd.host_ip = "10.0.2.2"` or `config.winnfsd.host_ip = "192.168.56.1"` in `Vagrantfile`_
  
3. Clone this project per https://github.com/uw-oap/shconfig, e.g. 

        git clone git@github.com:uw-oap/shconfig.git

4. Create SSH keys:

        ssh-keygen
        cp ~/.ssh/id_rsa path/to/shconfig/ssh_key
        cp ~/.ssh/id_rsa.pub path/to/shconfig/ssh_key.pub

   Then go to https://github.com/settings/keys and add a new SSH key. Paste in the ssh_key.pub content. Then go back to https://github.com/settings/keys and click "enable SSO"
   
4. If you would like, create SSH keys. Add the public key as an access key for each managed project as listed above. Put the private key in the shconfig directory as `ssh_key`.

5. If you would like, create a subdirectory called `repos`, and put each code repository into it. (If this directory doesn't exist, the code will be checked out using the ssh_key directly into the Vagrant machine.) For example:

        mkdir repos
		cd repos
		git clone FIXME

6. If you would like Vagrant to populate the database for you when the Vagrant machines are created, create a subdirectory called `db` and put a file named `<<dbname>>.sql` in it for each database you want to create. These can be any database name you like; a database will be created with whatever name is before `.sql` e.g. `mydb.sql` will create a database `mydb`. **Note: you may want to refresh these if it's been a while since the last Vagrant deployment.** For example:

        mkdir db
		cd db
		<<put FIXME.sql here>>

As of December 2019, you can now prepend a number to these files to ensure SQL files are imported in order. Anything prior to a hyphen gets stripped out of the name when figuring out the database name. For example, you can name your file `01-wordpress.sql` to ensure it's imported before another file.

7. The build process can take a long time, primarily because it will download and extract many RPMs, compile Perl, install many Perl modules, and compile multiple copies of PHP. If you have a tarball you would like Vagrant to explode for you to speed up this build process[^1], put it into shconfig with the name `vagrant-db.tgz` and/or `vagrant-web.tgz`. These files can save time in the build process.

8. `vagrant up`. Ideally this completes without error.

9. On your machine, add the contents of `/data/shconfig/run/dev/hosts` to your machine's `/etc/hosts` equivalent. It will probably be this:

        192.168.56.101 db.local
		192.168.56.102	web.local support.local
	    192.168.56.103 wp.local wordpress.local

Expected results:
- You can go to http://support.local and see RT running
- You can go to http://wordpress.local and see WordPress running
- You log in via HTTP BASIC auth; Vagrant loads with a couple of users; passwords can be set via

        vagrant ssh web
		htpasswd -b /etc/httpd/conf.d/passwords username password

- You can connect as a root database user[^2] to the database on db.local.

[^1]: These tarballs can be built like this, using an existing working Vagrant instance:

        vagrant ssh web
	    tar czvf /vagrant_data/vagrant-web.tgz /data/perlbrew /data/phpbrew /data/rt

[^2]: this access is controlled in several different places right now, prinicpally `src/dev/dev_db_grants.sql`, `src/mysql/sync_users.sql`, and `dev-vars/secrets.json`.




# How this project works

shconfig reads "source" templates from the `src/` directory, and renders these templates into `run/` using the variables in `vars/`.

shconfig also...

* auto-updates itself via git pull
* reads environment variables
* populates `vars/secrets.json` based on lastpass

## High level flow

1. `driver.sh` is run to update git. This code is as short as possible to minimize the chance of breaking it on update. `driver.sh` then calls...
2. `driver2.sh`. This does the bulk of the setup, prior to rendering `src/` into `run/`. When done, it calls...
3. `run/driver3.sh`. This is the rendered version of `src/driver3.sh`. This does the actual useful configuration.

## Variable namespaces

Variables defined in `vars/` are named with the prefix of the file they're in. For example if `vars/abc.json` contained:

    {'a': 1}
	
In configuration, this variable would be named `abc_a`. Any files in the directory `src/`, such as `src/example.sh`, that have the string `{{abc_a}}` will be "compiled" by driver into the `run/` directory; in this example, `run/example.sh` would then have `1` wherever `{{abc_a}}` was.

## Configuration templates

Files in `src/` are compiled using Jinja2. This templating language can do much more than variable replacement. For example, it is possible to build `{% if %}{% else %}{ %endif %}` blocks. That said, for ease of maintenance, templating should be limited to variable replacement.

# Design principles
## Idempotency

A fundamental design of `shconfig` is that you should be able to run `driver.sh` many times without anything bad happening. For example, you can run `driver.sh` 10 times and RT will only be installed once.

## shconfig configuration vs. other project configuration

shconfig should be the only project that knows passwords or server configuration, such as directory paths.

Other projects should _not_ have...

* passwords
* absolute URLs
* absolute paths
* references to hosts or ports

A common pattern is for shconfig to drop a `env.php` file in the root directory of a project; this file can have environment-specific data that the project can use.

## Keep things simple

Although it's ironic to say this due to the size of this project, a key philosophy has been to keep things simple through readable shell scripts and simple templating. This is why everything's written in Shell script rather than, say, Puppet config.

# Environment variables

## Required variables

These can be set in a file called `env.sh`; if this filename exists, it will be sourced when `driver.sh` is run.

* `$SHCONFIG_ENV_TYPE`: `dev`, `stg`, or `prd`
* `$SHCONFIG_APP_TYPE`: `web` or `db`
* `$SHCONFIG_OS_BASE`: for "shadow filesystem" code. This is used as a workaround to keep from having sudo access
* `$SHCONFIG_EMAIL`: who should get emails for this stuff
* `$SHCONFIG_DBSERVER`: fully qualified DNS name of the database server
* `$SHCONFIG_WEBSERVER`: fully qualified DNS name of the web server *as used by the database server's reverse DNS*. This is used in MySQL access grants.

## Optional variables

* `$FORCE_LASTPASS`: run lastpass even in `dev`
* `$SKIP_LASTPASS`: don't run lastpass
* `$SKIP_GITPULL`: don't `git pull` shconfig before running
* `$DEBUG`: set if you want to run with debug logging

For example, you can run

    SKIP_LASTPASS=1 DEBUG=1 ./driver.sh

# Special `vars/` files

Feel free to copy `protovars/` into `vars/` and edit as you see fit.

Special files:

* The file `shconfig.json` is built through the above environment variables.
* The file `driver.json` is built by `driver.sh`.
* The file `secrets.json` is built by `lastpass.sh`.

## Key directories

Using AP typical setup as defined in `vars/`, you'll see:

- `/data/shconfig`
- `/data/perlbrew` - Perl versions
- `/data/phpbrew` - PHP versions
- `/data/virtualenv` - Python versions
- `/data/[project]` - one entry per project

## Server initial setup

1. `ssh newserver`
3. Create SSH public/private key
4. `chmod 700 ~/.ssh && chmod 400 ~/.ssh/id_rsa`
5. Add SSH public key to every code repo
6. `git clone -b master https://path.to/shconfig.git /data/shconfig`
7. `cd /data/shconfig`
8. populate `/data/shconfig/env.sh`:

        SHCONFIG_OS_BASE=/data/os
        SHCONFIG_EMAIL=example@example.edu
        SHCONFIG_WEBSERVER=web.example.edu
        SHCONFIG_DBSERVER=db.example.edu

10. `DEBUG=1 ./driver.sh` -- in an ideal world this will work, and you will be asked for your LastPass username/password


# Maintenance

## Adding dev users

    vagrant ssh web
	sudo htpasswd /etc/httpd/conf.d/passwords <<username>>

## Restoring files after deployment

shconfig will wipe changed files from deployment directories after backing them up. A tarball is created from each deploy; see them in /data/shconfig/var/backup. These tarballs taken from the perspective of the root filesystem, so you should be able to restore them like this:

    tar -C / -xvf <<tarball-name>>


# FAQ

## Q. Why isn't vagrant starting Apache?

This could be a selinux issue. Try running:

    sudo setenforce 0
	sudo service httpd restart

## Q. How do I keep vagrant from using a ton of CPU?

Try halting your VMs, going to their VirtualBox settings, and going to System > Acceleration and turning off "enable nested paging."
## Q. How do I get a new version of PHP?

Set `FORCE_PHPBREW_UPDATE` to 1.

## Q. How can I increase the disk size of a VM?

https://askubuntu.com/a/1015068

    vagrant plugin install vagrant-disksize

and then add to the config

    db.disksize.size = '100GB'

Then in the VM:

    sudo yum install -y cloud-utils-growpart
    sudo growpart /dev/sda 1
    sudo xfs_growfs /
