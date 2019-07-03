# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.define "db" do |db|
    db.vm.box = "centos/7"
    db.vm.hostname = "vagrantdb.local"
    db.vm.network :private_network, ip: "192.168.100.101"
    db.vm.synced_folder ".", "/vagrant_data", nfs: true
    db.vm.synced_folder ".", "/vagrant", disabled: true
    db.vm.provision "shell", inline: <<-SHELL
set -o xtrace
yum -y install git
yum -y install python-virtualenv

# For MySQL 5.7:
yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
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
    DB_NAME=${i%%.sql}
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
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
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
    web.vm.network :private_network, ip: "192.168.100.102"
    web.vm.hostname = "vagrantweb.local"
    web.vm.synced_folder ".", "/vagrant_data", nfs: true
    web.vm.synced_folder ".", "/vagrant", disabled: true
    web.vm.provision "shell", inline: <<-SHELL
yum -y install git
yum -y install python-virtualenv
yum -y install unzip # for ckeditor

      # Apache:
yum -y install httpd mod_ssl mod_fcgid sendmail

      # For RT:
 yum -y install perl rpm patch gcc
 yum -y install expat-devel openssl-devel mariadb-devel

      # needed for WordPress:
 yum -y install php-mysql

      # needed for phpbrew:
 yum -y install make automake gcc gcc-c++ kernel-devel php php-devel php-pear bzip2-devel yum-utils bison libxslt-devel pcre-devel libcurl-devel libgsasl-devel openldap-devel readline-devel
 yum-builddep -y php
sudo systemctl enable httpd
sudo systemctl start httpd

sudo usermod -a -G apache vagrant

# Set up SSH keys
if [ -e /vagrant_data/ssh_key ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key ~vagrant/.ssh/id_rsa
fi

# Install web tarball, if any
if [ -e /vagrant_data/vagrant-web.tgz ]
then
  (cd / && tar xzf /vagrant_data/vagrant-web.tgz )
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
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
) > /data/shconfig/env.sh

chown -R vagrant:vagrant /data/shconfig
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL
  end

end
