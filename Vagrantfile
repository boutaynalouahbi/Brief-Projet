# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.hostname = "sysmonitor"
  config.vm.box = "ubuntu/jammy64"
 
  config.vm.box_check_update = false

  config.vm.network "private_network", ip: "192.168.56.10"

  # Synchroniser le dossier SysMonitor-Pro dans la VM
  config.vm.synced_folder "./SysMonitor-Pro", "/home/vagrant/SysMonitor-Pro"
  
  config.vm.provider "virtualbox" do |vb|
    # Customize the amount of memory on the VM:
    vb.memory = "2048"
    vb.cpus = 2

  end
   # 🔹 Provisionnement : exécute automatiquement apt-get update
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update -y
  SHELL

end
