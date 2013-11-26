require 'sinatra'
require './app'

set :logging, true
set :show_exceptions, false

run Sinatra::Application

