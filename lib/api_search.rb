require 'sinatra/base'
require 'cgi'
require 'nokogiri'
require 'base64'
require 'namae'
require 'ostruct'
require_relative 'helpers'
require_relative 'api'
require_relative 'volpino'

class ApiSearch
  include Sinatra::Api
  include Sinatra::Volpino
end
