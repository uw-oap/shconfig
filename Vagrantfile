# -*- mode: ruby -*-
# vi: set ft=ruby :

# 2020-07-06 jhb - Attempting to reduce CPU use
$enable_serial_logging = false


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
# 2021-08-25 adding config for winnfsd host_ip
Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?("vagrant-winnfsd")
      config.winnfsd.host_ip = "10.0.2.2"
  end
  # if more disk space is needed, uncomment this plus see README:
  # config.disksize.size = '100GB'
  config.vm.define "db" do |db|
    db.vm.box = "centos/7"
    db.vm.hostname = "vagrantdb.local"
    db.vm.network :private_network, ip: "192.168.56.101"
    db.vm.synced_folder ".", "/vagrant_data", nfs: true
    db.vm.synced_folder ".", "/vagrant", disabled: true
    db.vm.provision "shell", inline: <<-SHELL
set -o xtrace
yum -y install git
yum -y install python-virtualenv

yum -y upgrade
# For MySQL 5.7:
yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
# 2022-01-24 jhb - GPG key changed; need to import it
sudo rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
yum -y install mysql-community-server

sudo systemctl enable mysqld
sudo systemctl start mysqld

# unset root db password:
export MYSQL_PWD=$(perl -lne 'print $1 if /root.localhost: (.*)/' /var/log/mysqld.log)
echo "MYSQL_PWD set to $MYSQL_PWD"
mysql -u root --connect-expired-password <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY "$MYSQL_PWD";
uninstall plugin validate_password;
ALTER USER 'root'@'localhost' IDENTIFIED BY "";
FLUSH PRIVILEGES;
EOF
if [ $? -ne 0 ]
then
  echo "MySQL error: $?"
fi    
unset MYSQL_PWD
# Hack to make mysqld read the config file
echo "!includedir /etc/my.cnf.d/" >> /etc/my.cnf

# Set up SSH keys
if [ -e /vagrant_data/ssh_key ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key ~vagrant/.ssh/id_rsa
fi

# Install DB tarball, if any
if [ -e /vagrant_data/vagrant-db.tgz ]
then
  (cd / && tar xzf /vagrant_data/vagrant-db.tgz )
fi

# Install databases, if any:
if [ -e /vagrant_data/db ]
then
  pushd /vagrant_data/db
  for i in *.sql
  do
    FILE_NO_EXT=${i%%.sql}
    DB_NAME=${FILE_NO_EXT##*-}
    echo "CREATE DATABASE IF NOT EXISTS $DB_NAME;" | mysql -u root
    mysql -u root $DB_NAME < $i
  done
fi

# Set up /data/shconfig/
install -o vagrant -g vagrant -d /data
(cd /data && git clone /vagrant_data/ shconfig/)
(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=db"
 echo "SHCONFIG_OS_BASE=/data/os"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
 ) > /data/shconfig/env.sh
chown -R vagrant:vagrant /data/shconfig
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL
  end
  
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
  end

  config.vm.define "web" do |web|
    web.vm.box = "centos/7"
    web.vm.network :private_network, ip: "192.168.56.102"
    web.vm.hostname = "vagrantweb.local"
    web.vm.synced_folder ".", "/vagrant_data", nfs: true
    web.vm.synced_folder ".", "/vagrant", disabled: true
    web.vm.provision "shell", inline: <<-SHELL
# Install web tarball, if any
if [ -e /vagrant_data/vagrant-web.tgz ]
then
  (cd / && tar xzf /vagrant_data/vagrant-web.tgz )
else
  echo "A note from the Office of Academic Personnel:"
  echo
  echo "Please consider populating vagrant-web.tgz. Otherwise this build will take"
  echo "a long, long time."
  echo
  echo "... sleeping 60 seconds to give you a taste for how long you'll have to wait ..."
  sleep 30
  echo "... it will be hours ..."
  sleep 30
  echo "OK; continuing and building from scratch."
fi

yum -y upgrade

yum -y install git
yum -y install python-virtualenv
yum -y install unzip # for ckeditor

      # Apache:
yum -y install httpd mod_ssl mod_fcgid sendmail

# FIXME need to install these via driver somehow:
yum -y install spamassassin lastpass-cli

      # For RT:
 yum -y install perl rpm patch gcc
 yum -y install expat-devel openssl-devel mariadb-devel

      # needed for WordPress:
 yum -y install php-mysql

      # needed for phpbrew:
 yum -y install make automake gcc gcc-c++ kernel-devel php php-devel php-pear bzip2-devel yum-utils bison libxslt-devel pcre-devel libcurl-devel libgsasl-devel openldap-devel readline-devel
 yum-builddep -y php
  #   apt-get install -y apache2          
sudo systemctl enable httpd
sudo systemctl start httpd

sudo usermod -a -G apache vagrant

# Set up SSH keys
if [ -e /vagrant_data/ssh_key ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key ~vagrant/.ssh/id_rsa
fi

if [ -e /vagrant_data/repos ]
then
  mkdir -p /data
  echo "Linking repos from /vagrant_data/repos to /data is left as an exercise for the reader"
fi

# Set up /data/shconfig
install -o vagrant -g vagrant -d /data
(cd /data && git clone /vagrant_data/ shconfig/)
(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=web"
 echo "SHCONFIG_OS_BASE=/data/os"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
) > /data/shconfig/env.sh

# Set up HTTP BASIC auth passwords:
sudo htpasswd -cb /etc/httpd/conf.d/passwords FIXME FIXME

chown -R vagrant:vagrant /data/shconfig

# add github to known_hosts:
ssh-keyscan -t rsa github.com >> ~vagrant/.ssh/known_hosts
chown -R vagrant:vagrant ~vagrant/.ssh
sudo -iu vagrant FORCE_PHPBREW_UPDATE=1 /data/shconfig/driver.sh
# Installing RT modules requires a second run:
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL

    web.trigger.after :up do |trigger|
      trigger.run_remote = {inline: "sudo service httpd restart"}
    end

  end

  config.vm.define "wp" do |wp|
    wp.vm.box = "centos/7"
    wp.vm.network :private_network, ip: "192.168.56.103"
    wp.vm.hostname = "vagrantwp.local"
    wp.vm.synced_folder ".", "/vagrant_data", nfs: true
    wp.vm.synced_folder ".", "/vagrant", disabled: true
    wp.vm.provision "shell", inline: <<-SHELL
# Install wp tarball, if any
if [ -e /vagrant_data/vagrant-wp.tgz ]
then
  (cd / && tar xzf /vagrant_data/vagrant-wp.tgz )
fi

yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi-php74
yum -y install php php-cli mod_php php-mbstring
yum -y upgrade
yum -y install git
yum -y install python-virtualenv
yum -y install unzip # for ckeditor

      # Apache:
yum -y install httpd mod_ssl mod_fcgid sendmail

# FIXME need to install these via driver somehow:
yum -y install spamassassin lastpass-cli

      # needed for PRIME and WordPress:
 yum -y install php-mysql

      # needed for phpbrew:
 yum -y install make automake gcc gcc-c++ kernel-devel php php-devel php-pear bzip2-devel yum-utils bison libxslt-devel pcre-devel libcurl-devel libgsasl-devel openldap-devel readline-devel
 yum-builddep -y php
  #   apt-get install -y apache2          
sudo systemctl enable httpd
sudo systemctl start httpd

sudo usermod -a -G apache vagrant

# Set up SSH keys
if [ -e /vagrant_data/ssh_key ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key ~vagrant/.ssh/id_rsa
fi

if [ -e /vagrant_data/repos ]
then
  mkdir -p /data
  echo "Linking repos from /vagrant_data/repos to /data is left as an exercise for the reader"
fi

# Set up /data/shconfig
install -o vagrant -g vagrant -d /data
(cd /data && git clone /vagrant_data/ shconfig/)
(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=wp"
 echo "SHCONFIG_OS_BASE=/data/os"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
) > /data/shconfig/env.sh

# Set up HTTP BASIC auth passwords:
sudo htpasswd -cb /etc/httpd/conf.d/passwords FIXME FIXME

chown -R vagrant:vagrant /data/shconfig
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL

    wp.trigger.after :up do |trigger|
      trigger.run_remote = {inline: "sudo service httpd restart"}
    end

  end

end
