# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Install latest version of Chef
  config.omnibus.chef_version = :latest


  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "precise64"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
#  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  # Override settings for specific providers

  # Local virtual machine via Virtualbox
  config.vm.provider :virtualbox do |vb, override|
    vb.name = "cr-search"
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end

  # Remote virtual machine in the AWS cloud
  config.vm.provider :aws do |aws, override|
    aws.access_key_id = "[REDACTED]"
    aws.secret_access_key = "[REDACTED]"
    aws.region = "eu-west-1"
    aws.keypair_name = "vagrant"
    #aws.security_groups = ["sg-36e6f354"]
    aws.instance_type = "m1.small"
    aws.ami = "ami-8e987ef9"
    aws.tags = { Name: 'Vagrant cr-search' }

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "~/.ssh/aws/vagrant.pem"
  end

 
  config.vm.hostname = "cr-search"

  # Assign this VM to a host-only network IP, allowing you to access it
  # via the IP. Host-only networks can talk to the host machine as well as
  # any other machines on the same network, but cannot be accessed (through this
  # network interface) by any external networks.
  config.vm.network :private_network, ip: "33.33.33.66"
  
  # Forward a port from the guest to the host, which allows for outside
  # computers to access the VM, whereas host only networking does not.
  config.vm.network :forwarded_port, guest: 80, host: 8080 # Apache2

  # Enable provisioning with chef solo, specifying a cookbooks path, roles
  # path, and data_bags path (all relative to this Vagrantfile), and adding 
  # some recipes and/or roles.
  #
  config.vm.provision :chef_solo do |chef|
    chef.log_level = :debug
    dna = JSON.parse(File.read("node.json"))
    dna.delete("run_list").each do |recipe|
      chef.add_recipe(recipe)
    end
    chef.json.merge!(dna)
  end
end
