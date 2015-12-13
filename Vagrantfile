# -*- mode: ruby -*-
# vi: set ft=ruby :

def installed_plugins(required_plugins)
  required_plugins.reduce([]) do |missing, plugin|
    if Vagrant.has_plugin?(plugin)
      missing
    else
      puts "#{plugin} plugin is missing. Installing..."
      %x(set -x; vagrant plugin install #{plugin})
      missing << plugin
    end
  end
end

def load_env
  # requires dotenv plugin/gem
  require "dotenv"

  # make sure DOTENV is set, defaults to "default"
  ENV["DOTENV"] ||= "default"

  # load ENV variables from file specified by DOTENV
  # use .env with DOTENV=default
  filename = ENV["DOTENV"] == "default" ? ".env" : ".env.#{ENV['DOTENV']}"
  Dotenv.load! File.expand_path("../#{filename}", __FILE__)
rescue LoadError
  $stderr.puts "Please install dotenv plugin with \"vagrant plugin install dotenv\""
  exit
rescue Errno::ENOENT
  $stderr.puts "Please create #{filename} file, or use DOTENV=example for example configuration"
  exit
end

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here.

  # Check if required plugins are installed.
  required_plugins = %w{ vagrant-omnibus vagrant-bindfs dotenv }

  unless installed_plugins(required_plugins).empty?
    puts "Plugins have been installed, please rerun vagrant."
    exit
  end

  # load ENV variables
  load_env

  # Install latest version of Chef
  config.omnibus.chef_version = "12.5.1"

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "bento/ubuntu-14.04"

  # Enable provisioning with chef solo
  config.vm.provision :chef_solo do |chef|
    chef.json = { "dotenv" => ENV["DOTENV"], "application" => ENV["APPLICATION"] }
    chef.custom_config_path = "Vagrantfile.chef"
    chef.cookbooks_path = "vendor/cookbooks"
    dna = JSON.parse(File.read(File.expand_path("../node.json", __FILE__)))
    dna.delete("run_list").each do |recipe|
      chef.add_recipe(recipe)
    end
    chef.json.merge!(dna)
    chef.log_level = ENV["LOG_LEVEL"].to_sym
  end

  # allow multiple machines, specified by DOTENV
  config.vm.define ENV["DOTENV"] do |machine|
    # Override settings for specific providers
    machine.vm.provider :virtualbox do |vb, override|
      vb.name = "#{ENV["APPLICATION"]}.virtualbox"
      vb.customize ["modifyvm", :id, "--memory", "2048"]
      unless Vagrant::Util::Platform.windows?
        # Disable default synced folder before bindfs tries to bind to it
        override.vm.synced_folder ".", "/var/www/#{ENV['APPLICATION']}", disabled: true
        override.vm.synced_folder ".", "/vagrant", id: "vagrant-root", nfs: true
        override.bindfs.bind_folder "/vagrant", "/var/www/#{ENV['APPLICATION']}",
                                    :owner => "900",
                                    :group => "900",
                                    :"create-as-user" => true,
                                    :perms => "u=rwx:g=rwx:o=rwx",
                                    :"create-with-perms" => "u=rwx:g=rwx:o=rwx",
                                    :"chown-ignore" => true,
                                    :"chgrp-ignore" => true,
                                    :"chmod-ignore" => true
      end
    end

    machine.vm.provider :vmware_fusion do |fusion|
      fusion.vmx["memsize"] = "2048"
      fusion.vmx["numvcpus"] = "2"
    end

    machine.vm.provider :aws do |aws, override|
      # please configure in .env
      aws.access_key_id = ENV.fetch('AWS_KEY', nil)
      aws.secret_access_key = ENV.fetch('AWS_SECRET', nil)
      aws.keypair_name = ENV.fetch('AWS_KEYNAME', nil)
      override.ssh.username = "ubuntu"
      override.ssh.private_key_path = ENV.fetch('SSH_PRIVATE_KEY', nil)

      aws.security_groups = ENV.fetch('AWS_SECURITY_GROUP', "default")
      aws.instance_type = ENV.fetch('AWS_INSTANCE_TYPE', nil)
      aws.ami = ENV.fetch('AWS_AMI', nil)
      aws.region = ENV.fetch('AWS_REGION', "us-east-1")
      aws.tags = { Name: ENV["APPLICATION"] }

      override.nfs.functional = false
      override.vm.synced_folder ".", "/var/www/#{ENV['APPLICATION']}", type: "rsync", rsync__exclude: [".git/", ".bundle/", "vendor/bundle/ruby"]

      override.vm.box_url = "https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box"
    end

    machine.vm.provider :digital_ocean do |digital_ocean, override|
      # please configure in .env
      override.ssh.private_key_path = ENV.fetch('SSH_PRIVATE_KEY', nil)
      digital_ocean.token = ENV.fetch('DO_PROVIDER_TOKEN', nil)
      digital_ocean.size = ENV.fetch('DO_SIZE', nil)

      override.vm.box = 'digital_ocean'
      override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"
      override.ssh.username = "ubuntu"
      digital_ocean.region = 'nyc2'
      digital_ocean.image = 'ubuntu-14-04-x64'
    end

    machine.vm.hostname = ENV.fetch('HOSTNAME')
    machine.vm.network :private_network, ip: ENV.fetch('PRIVATE_IP', nil)
    machine.vm.network :public_network
    machine.vm.synced_folder ".", "/var/www/#{ENV['APPLICATION']}", id: "vagrant-root"
  end
end
