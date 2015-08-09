def whyrun_supported?
  true
end

use_inline_resources

def load_current_resource
  @current_resource = Chef::Resource::Dotenv.new(new_resource.name)
end

action :load do
  chef_gem "dotenv" do
    compile_time true if respond_to?(:compile_time)
    action :install
  end

  # find file specified by dotenv atrribute
  # use .env when dotenv is "default"
  require 'dotenv'
  ENV["DOTENV"] = new_resource.dotenv
  filename = new_resource.dotenv == "default" ? ".env" : ".env.#{new_resource.dotenv}"
  filepath = "/var/www/#{new_resource.name}/shared/#{filename}"

  # create application root folder, subfolders, and set permissions if they don't exist
  %W{ #{new_resource.name} #{new_resource.name}/shared #{new_resource.name}/shared/public }.each do |dir|
    directory "/var/www/#{dir}" do
      owner new_resource.user
      group new_resource.group
      mode '0755'
      recursive true
      action :nothing
    end.run_action(:create)
  end

  # create .env file from template if we don't find it
  template filepath do
    source "env.erb"
    owner new_resource.user
    group new_resource.group
    mode '0755'
    cookbook 'dotenv'
    variables(
      :application    => new_resource.name,
      :rails_env      => new_resource.rails_env,
      :user => new_resource.user,
      :group => new_resource.group
    )
    action :nothing
  end.run_action(:create)

  # load ENV variables from file specified by dotenv atrribute
  ::Dotenv.load! filepath
end
