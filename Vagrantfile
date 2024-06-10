Vagrant.configure("2") do |config|
    config.vm.define "vm1" do |vm1|
        vm1.vm.box = "debian/bullseye64"
        vm1.vm.hostname = 'icpdock.local'
        vm1.vm.network "public_network", type: "dhcp"
        config.vm.provider "virtualbox" do |vbox|
            vbox.name = "icpdock"
            vbox.gui = false
            vbox.cpus = 4
            vbox.memory = 4096
            vbox.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
        end
    end
end

