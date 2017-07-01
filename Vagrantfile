# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.provision :shell, path: "installapache.sh"
  config.vm.network "private_network", ip: "192.168.50.4"
end
