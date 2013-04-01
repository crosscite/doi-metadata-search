require 'rubygems'
require 'bundler'

Bundler.require
 
disable :run, :reload

require './app'

run Sinatra::Application
