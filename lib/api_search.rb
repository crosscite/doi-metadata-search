require 'sinatra/base'
require 'cgi'
require 'nokogiri'
require 'base64'
require 'namae'
require 'ostruct'
require_relative 'helpers'
require_relative 'api'
require_relative 'volpino'
require_relative 'lagottino'

# convenience class for testing
class ApiSearch
  include Sinatra::Api
  include Sinatra::Volpino
  include Sinatra::Lagottino
  include Sinatra::Helpers
end
