# Scripts to run on all Vagrant machines
set -e

# Set up SSH keys
if [ -e /vagrant_data/ssh_key ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key ~vagrant/.ssh/id_rsa
fi

if [ -e /vagrant_data/ssh_key_ed25519 ]
then
  install -CD -o vagrant -g vagrant -m 0400 /vagrant_data/ssh_key_ed25519 ~vagrant/.ssh/id_ed25519
fi

ssh-keyscan -t rsa github.com >> ~vagrant/.ssh/known_hosts

# Create a bash_profile
cat > ~vagrant/.bash_profile <<EOF
source ~/.bashrc

HISTCONTROL=""
EOF
sudo chown -R vagrant:vagrant ~vagrant/

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get -y install python3.10 python3.10-venv

install -o vagrant -g vagrant -d /data

cd /data
git clone /vagrant_data/ shconfig/
