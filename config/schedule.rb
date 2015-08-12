# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

begin
  # make sure DOTENV is set
  ENV["DOTENV"] ||= "default"

  # load ENV variables from file specified by DOTENV
  # use .env with DOTENV=default
  filename = ENV["DOTENV"] == "default" ? ".env" : ".env.#{ENV['DOTENV']}"

  fail Errno::ENOENT unless File.exist?(File.expand_path("../../#{filename}", __FILE__))

  # load ENV variables from file specified by APP_ENV, fallback to .env
  require "dotenv"
  Dotenv.load! filename
rescue Errno::ENOENT
  $stderr.puts "Please create file .env in the application root folder"
  exit
rescue LoadError
  $stderr.puts "Please install dotenv with \"gem install dotenv\""
  exit
end

env :PATH, ENV['PATH']
env :DOTENV, ENV['DOTENV']
set :environment, ENV['RACK_ENV']
set :output, "log/cron.log"

# every hour at 5 min past the hour
every "5 * * * *" do
  rake "sidekiq:monitor"
end
