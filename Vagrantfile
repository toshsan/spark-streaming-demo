Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"
  config.vm.synced_folder "/Users/ssahoo/dotfiles", "/dotfiles", create:true
  config.vm.provision "shell", path: "bootstrap.sh"
  config.ssh.private_key_path = "/Users/ssahoo/.ssh/id_rsa"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024*2
  end

  config.vm.define "node1" do |node|
	  node.vm.hostname = "node1"
    node.vm.network "private_network", ip: "192.168.20.11"

    node.vm.provider "virtualbox" do |vb|
        vb.memory = 1024*4
    end
  end

  config.vm.define "node2" do |node|
	  node.vm.hostname = "node2"
    node.vm.network "private_network", ip: "192.168.20.12"
  end

  config.vm.define "node3" do |node|
	  node.vm.hostname = "node3"
    node.vm.network "private_network", ip: "192.168.20.13"
  end

end
