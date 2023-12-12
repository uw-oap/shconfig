# -*- mode: ruby -*-
# vi: set ft=ruby :

if Vagrant::Util::Platform.darwin? then
  PROVIDER = "vmware_fusion"
  IMAGE = "bento/ubuntu-22.04-arm64"
else
  PROVIDER = "virtualbox"
  IMAGE = "ubuntu/jammy64"
end

Vagrant.configure("2") do |config|
  config.vm.provider PROVIDER do |v|
    v.memory = 1024
  end

  config.vm.define "db3" do |db|
      db.vm.provider PROVIDER do |vb|
          vb.memory = 2048
      end

    # db.disksize.size = '100GB'
    db.vm.box = IMAGE
    db.vm.hostname = "vagrantdb.local"
    db.vm.synced_folder ".", "/vagrant_data"
    db.vm.synced_folder ".", "/vagrant", disabled: true

    if PROVIDER == "vmware_fusion"
      db.vm.network :private_network
    else
      db.vm.network :private_network, ip: "192.168.56.101"
    end

    db.vm.provision "shell", inline: <<-SHELL
set -o xtrace
/bin/bash /vagrant_data/bin/vagrant_all.sh
/bin/bash /vagrant_data/bin/vagrant_db.sh

chown -R vagrant:vagrant /data/shconfig
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL
  end
  
  config.vm.define "web3" do |web|
      # web.disksize.size = '100GB'
      web.vm.provider PROVIDER do |vb|
          vb.memory = 2048
      end
    web.vm.box = IMAGE
    web.vm.hostname = "vagrantweb.local"
    web.vm.synced_folder ".", "/vagrant_data"
    web.vm.synced_folder ".", "/vagrant", disabled: true

    if PROVIDER == "vmware_fusion"
      web.vm.network :private_network
    else
      web.vm.network :private_network, ip: "192.168.56.102"
    end

    web.vm.provision "shell", inline: <<-SHELL
set -o xtrace
/bin/bash /vagrant_data/bin/vagrant_all.sh
/bin/bash /vagrant_data/bin/vagrant_ssl.sh
/bin/bash /vagrant_data/bin/vagrant_web.sh

chown -R vagrant:vagrant ~vagrant/.ssh
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL

    web.trigger.after :up do |trigger|
      trigger.run_remote = {inline: "sudo service apache2 restart"}
    end

  end

  config.vm.define "wp3" do |wp|
    wp.vm.box = "bento/ubuntu-22.04-arm64"
    wp.vm.hostname = "vagrantwp.local"
    wp.vm.synced_folder ".", "/vagrant_data"
    wp.vm.synced_folder ".", "/vagrant", disabled: true

    if PROVIDER == "vmware_fusion"
      wp.vm.network :private_network
    else
      wp.vm.network :private_network, ip: "192.168.56.103"
    end

    wp.vm.provision "shell", inline: <<-SHELL
set -o xtrace
/bin/bash /vagrant_data/bin/vagrant_all.sh
/bin/bash /vagrant_data/bin/vagrant_ssl.sh
/bin/bash /vagrant_data/bin/vagrant_wp.sh

chown -R vagrant:vagrant /data/shconfig
sudo -iu vagrant /data/shconfig/driver.sh
    SHELL

    wp.trigger.after :up do |trigger|
      trigger.run_remote = {inline: "sudo service apache2 restart"}
    end

  end

  # 2023-04-26 - is this in the right place?
  config.trigger.after [:provision] do |t|
    t.name = "Reboot after provisioning"
    t.run = { :inline => "vagrant reload" }
  end
end
