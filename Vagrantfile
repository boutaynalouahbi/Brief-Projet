# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

config.vm.define "web-server" do |web|
    web.vm.box = "ubuntu/jammy64"
    web.vbguest.auto_update = true
    web.vm.hostname = "web-server"

    # Port  (3306 -> 3307 sur l’hôte)
    web.vm.network "forwarded_port", guest: 80, host: 8080

    # Réseau privé
    web.vm.network "private_network", ip: "192.168.56.10"

    # Dossier partagé
   web.vm.synced_folder "./website/", "/var/www/html/", type: "rsync"

    
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    # Provisionnement
    web.vm.provision "shell", path: "./scripts/provision-web-ubuntu.sh"
  end

  
  config.vm.define "db-server" do |db|
    db.vm.box = "centos/stream9"
    db.vbguest.auto_update = true
    db.vm.hostname = "db-server"

    # Port MySQL (3306 -> 3307 sur l’hôte)
    db.vm.network "forwarded_port", guest: 3306, host: 3307

    # Réseau privé
    db.vm.network "private_network", ip: "192.168.56.20"

    # Dossier partagé
    # db.vm.synced_folder "./database", "/vagrant/database", type: "rsync"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end

    # Provisionnement
    db.vm.provision "shell", path: "./scripts/provision-db-centos.sh"
  end

end
