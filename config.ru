Encoding.default_external = Encoding::UTF_8

require 'rubygems'
require 'bundler'

Bundler.require
require 'sass/plugin/rack'
require './app'

# use scss for stylesheets
Sass::Plugin.options[:style] = :compressed
use Sass::Plugin::Rack

run Sinatra::Application
