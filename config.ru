require 'sinatra'
require './app'

FileUtils.mkdir_p 'log' unless File.exists?('log')
out_log = File.new('log/out.log', 'a')
err_log = File.new('log/err.log', 'a')
$stdout.reopen(out_log)
$stderr.reopen(err_log)
$stdout.sync = true
$stderr.sync = true

set :logging, true
set :show_exceptions, false

run Sinatra::Application

