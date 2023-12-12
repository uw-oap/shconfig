set -e

sudo apt-get -y install apache2

# turn on Apache modules:
sudo a2enmod ssl headers rewrite
sudo apt-get -y install php8.1 php8.1-fpm libapache2-mod-php php8.1-mysql
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.1-fpm
sudo systemctl restart apache2
sudo systemctl restart php8.1-fpm

sudo systemctl enable apache2
sudo systemctl start apache2

sudo usermod -a -G www-data vagrant

# Set up HTTP BASIC auth passwords:
sudo htpasswd -cb /etc/apache2/passwords jld36 jld36
sudo htpasswd -b /etc/apache2/passwords borwick borwick

if [ -e /vagrant_data/repos ]
then
  mkdir -p /data
  ln -s /vagrant_data/repos/apweb-source /data/wp
  ln -s /vagrant_data/repos/hiringplan /data/hiringplan
  ln -s /vagrant_data/repos/rolling-due-dates /data/rollingdates
  ln -s /vagrant_data/repos/jobboard /data/jobboard
  ln -s /vagrant_data/repos/ptinfo /data/ptinfo
  chmod g+rx /vagrant_data
fi

(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=wp"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
) > /data/shconfig/env.sh
