set -e

export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y install podman mysql-client apache2 libapache2-mod-xsendfile

# needed to build cross-platform podman images
sudo apt-get -y install qemu-user-static

# needed for datapipe RPMs:
sudo apt-get -y install gcc-x86-64-linux-gnu g++ python3-dev

# turn on Apache modules:
sudo a2enmod ssl headers rewrite proxy proxy_http
sudo apt-get -y install php libapache2-mod-php php-mysql

# needed for RT:
sudo apt-get -y install libdbd-sqlite3-perl libssl-dev zlib1g-dev libexpat1-dev libmysqlclient-dev libapache2-mod-fcgid make

# needed for python to build datapipe stuff + for EDW
sudo apt-get -y install unixodbc-dev python3-dev
sudo apt-get -y install krb5-user

sudo systemctl enable apache2
sudo systemctl start apache2

sudo usermod -a -G www-data vagrant

if [ -e /vagrant_data/repos ]
then
  mkdir -p /data
  ln -s /vagrant_data/repos/datapipe /data/datapipe
  ln -s /vagrant_data/repos/portal4 /data/portal
  ln -s /vagrant_data/repos/lux /data/lux
  # ln -s /vagrant_data/repos/prime-source /data/prime
  chmod g+rx /vagrant_data
fi

# needed for EDW connections; see https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver16&tabs=ubuntu18-install%2Calpine17-install%2Cdebian8-install%2Credhat7-13-install%2Crhel7-offline

curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list
apt-get update
ACCEPT_EULA=Y apt-get install -y msodbcsql18

# Set up HTTP BASIC auth passwords:
sudo htpasswd -cb /etc/apache2/passwords jld36 jld36
sudo htpasswd -b /etc/apache2/passwords borwick borwick

# install mailcatcher
sudo apt-get -y install ruby-full
sudo gem install mailcatcher

# thanks to https://gist.github.com/munkiepus/272e07b9dd2db57c7ecb3d79faf3cf18
echo '[Unit]
Description = MailCatcher
After=network.target
After=systemd-user-sessions.service
[Service]
Type=simple
Restart=on-failure
User=vagrant
ExecStart=/usr/local/bin/mailcatcher --foreground --smtp-ip 0.0.0.0 --ip 0.0.0.0
[Install]
WantedBy=multi-user.target
' >> /tmp/mailcatcher.service
sudo mv /tmp/mailcatcher.service /etc/systemd/system/mailcatcher.service
sudo chmod 644 /etc/systemd/system/mailcatcher.service

sudo systemctl enable mailcatcher
sudo service mailcatcher start

(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=web"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
) > /data/shconfig/env.sh

