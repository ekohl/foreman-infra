# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "shell", inline: <<-SHELL
    yum -y install epel-release
    yum -y install puppet6-release || yum -y install https://yum.puppetlabs.com/puppet6/puppet6-release-el-7.noarch.rpm
    yum -y install puppet-agent
  SHELL

  config.vm.provision "puppet" do |puppet|
    puppet.module_path = ["puppet/modules", "puppet/git_modules", "puppet/forge_modules"]
    puppet.manifests_path = "vagrant/manifests"
    puppet.synced_folder_type = "rsync"
  end

  config.vm.define "jenkins-master" do |override|
    override.vm.hostname = "jenkins-master"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "2048"
    end
  end

  config.vm.define "web" do |override|
    override.vm.hostname = "web"

    override.vm.provider "libvirt" do |libvirt|
      libvirt.memory = "2048"
    end
  end
end
