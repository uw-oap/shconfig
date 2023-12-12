set -e

export DEBIAN_FRONTEND=noninteractive
sudo apt-get -y install mysql-client mysql-server

perl -i.bak -pe 's|127.0.0.1|0.0.0.0|g' /etc/mysql/mysql.conf.d/mysqld.cnf

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
    echo "Loading $i..."
    FILE_NO_EXT=${i%%.sql}
    DB_NAME=${FILE_NO_EXT##*-}
    echo "CREATE DATABASE IF NOT EXISTS $DB_NAME;" | sudo mysql -u root
    sudo mysql -u root $DB_NAME < $i
    echo "...done loading."
  done
fi

if [ -e /vagrant_data/repos ]
then
  ln -s /vagrant_data/repos/data-audit /data/data-audit
  ln -s /vagrant_data/repos/dbmanager /data/dbmanager

  # 2023-10-12 - move var/ in case it exists from a previous run
  if [ -e /data/dbmanager/var ]
  then
    # TODO make this create a unique name
    mv /data/dbmanager/var /data/dbmanager/var-old
  fi
fi


# Set up /data/shconfig/
(echo "SHCONFIG_ENV_TYPE=dev"
 echo "SHCONFIG_APP_TYPE=db"
 echo "SHCONFIG_EMAIL=nobody@example.edu"
 echo "SHCONFIG_CRONEMAIL=nobody@example.edu"
 echo "SHCONFIG_DBSERVER=db.local"
 echo "SHCONFIG_WEBSERVER=web.local"
 echo "SHCONFIG_WPSERVER=wp.local"
 ) > /data/shconfig/env.sh
