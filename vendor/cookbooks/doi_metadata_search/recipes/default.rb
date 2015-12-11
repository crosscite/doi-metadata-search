# load .env configuration file with ENV variables
# copy configuration file to shared folder
dotenv node["application"] do
  dotenv          node["dotenv"]
  action          :nothing
end.run_action(:load)

# install and configure dependencies
include_recipe "apt"
include_recipe "mongodb::10gen_repo"
include_recipe "mongodb::default"
include_recipe "nodejs"

# install nginx and create configuration file and application root
passenger_nginx node["application"] do
  user            ENV['DEPLOY_USER']
  group           ENV['DEPLOY_GROUP']
  action          :config
end

# create required files and folders, and deploy application
capistrano node["application"] do
  user            ENV['DEPLOY_USER']
  group           ENV['DEPLOY_GROUP']
  rails_env       ENV['RAILS_ENV']
  action          [:config, :bundle_install, :npm_install, :consul_install, :precompile_assets, :whenever, :restart]
end
