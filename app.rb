# # load ENV variables from .env file if it exists
env_file =  File.expand_path("../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

require 'securerandom'
require 'active_support/all'

# required ENV variables, can be set in .env file
ENV['APPLICATION'] ||= "doi-metadata-search"
ENV['SECRET_KEY_BASE'] ||= SecureRandom.hex(15)
ENV['SITE_TITLE'] ||= "DataCite Search"
ENV['LOG_LEVEL'] ||= "info"
ENV['RA'] ||= "datacite"
ENV['TRUSTED_IP'] ||= "172.0.0.0/8"
ENV['API_URL'] ||= "https://api.datacite.org"

env_vars = %w(SITE_TITLE LOG_LEVEL RA API_URL SECRET_KEY_BASE)
env_vars.each { |env| fail ArgumentError,  "ENV[#{env}] is not set" unless ENV[env].present? }

# Constants
MIN_MATCH_SCORE = 2
MIN_MATCH_TERMS = 3
MAX_MATCH_TEXTS = 1000
TYPICAL_ROWS = [10, 20, 50, 100, 500]
DEFAULT_ROWS = 25
MONTH_SHORT_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
ORCID_VERSION = '1.2'

require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'sinatra/cookies'
require 'tilt/haml'
require 'haml'
require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate-bootstrap'
require 'cgi'
require 'maremma'
require 'gabba'
require 'rack-flash'
require 'jwt'
require 'open-uri'
require 'uri'
require 'better_errors'

Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

configure do
  set :root, File.dirname(__FILE__)

  # Configure sessions and flash
  use Rack::Session::Cookie, secret: ENV['SECRET_KEY_BASE']
  use Rack::Flash

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Enable logging
  enable :logging

  # Citation format types
  set :citation_formats,
      'bibtex' => 'application/x-bibtex',
      'ris' => 'application/x-research-info-systems',
      'apa' => 'text/x-bibliography; style=apa',
      'harvard' => 'text/x-bibliography; style=harvard1',
      'ieee' => 'text/x-bibliography; style=ieee',
      'mla' => 'text/x-bibliography; style=modern-language-association',
      'vancouver' => 'text/x-bibliography; style=vancouver',
      'chicago' => 'text/x-bibliography; style=chicago-fullnote-bibliography',
      'citeproc' => 'application/vnd.citationstyles.csl+json'

  # Set facet fields
  set :facet_fields, %w(resourceType_facet publicationYear datacentre_facet rightsURI)

  # Google analytics event tracking
  set :ga, Gabba::Gabba.new(ENV['GABBA_COOKIE'], ENV['GABBA_URL']) if ENV['GABBA_COOKIE']

  # optionally use Bugsnag for error tracking
  if ENV['BUGSNAG_KEY']
    require 'bugsnag'
    Bugsnag.configure do |config|
      config.api_key = ENV['BUGSNAG_KEY']
      config.project_root = settings.root
      config.app_version = App::VERSION
      config.release_stage = ENV['RACK_ENV']
      config.notify_release_stages = %w(production stage development)
    end

    use Bugsnag::Rack
    enable :raise_errors
  end
end

configure :development do
  use BetterErrors::Middleware
  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP']
  BetterErrors.application_root = File.expand_path('..', __FILE__)

  enable :raise_errors, :dump_errors
  # disable :show_exceptions
end

before do
  @page = params.fetch('page', 1).to_i
  @offset = DEFAULT_ROWS * (@page - 1)
  @meta = {}
end

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/' do
  @meta = { page: "splash" }

  haml :splash
end

get '/works' do
  @works = get_works(query: params[:query], offset: @offset, 'publisher-id' => params['publisher-id'], 'resource-type-id' => params['resource-type-id'], 'year' => params['year'])

  # check for existing claims if user is logged in
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user

  # pagination
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "works"
  haml :'works/index'
end

get %r{/works/(.+)} do
  params["id"] = params[:captures].first

  # workaround, as nginx swallows double backslashes
  params["id"] = params["id"].gsub(/(http|https):\/+(\w+)/, '\1://\2')

  @work = get_works(id: params["id"])

  # check for existing claims if user is logged in and work is registered with DataCite
  if current_user
    @work[:data] = get_claimed_items(current_user, [@work[:data]]).first
  end

  @contributions = get_contributions("work-id" => params["id"], "source-id" => params["source-id"], "publisher-id" => params["publisher-id"], offset: @offset, rows: 100)
  @relations = get_relations("work-id" => params["id"], "source-id" => params["source-id"], "relation-type-id" => params["relation-type-id"], offset: @offset, rows: 25)

  # check for existing claims if user is logged in
  if current_user
    @contributions[:data] = get_claimed_items(current_user, @contributions.fetch(:data, []))
    @relations[:data] = get_claimed_items(current_user, @relations.fetch(:data, []))
  end

  # pagination for relations
  @relations[:data] = pagination_helper(@relations[:data], @page, @relations.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "works"
  haml :'works/show'
end

get '/contributors' do
  @contributors = get_contributors(query: params[:query], offset: @offset)

  # pagination
  @contributors[:data] = pagination_helper(@contributors[:data], @page, @contributors.fetch(:meta, {}).fetch("total", 0))

  haml :'contributors/index'
end

get '/contributors/:id' do
  id = validate_orcid(params[:id]) ? "orcid.org/#{params[:id]}" : "https://github.com/#{params[:id]}"

  @contributor  = get_contributors(id: id)

  @contributions = get_contributions("contributor-id" => id, "source-id" => params["source-id"], "publisher-id" => params["publisher-id"], offset: @offset)

  # check for existing claims if user is logged in
  @contributions[:data] = get_claimed_items(current_user, @contributions.fetch(:data, [])) if current_user

  # pagination
  @contributions[:data] = pagination_helper(@contributions[:data], @page, @contributions.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "contributors"
  haml :'contributors/show'
end

get '/data-centers' do
  @datacenters  = get_datacenters(query: params[:query], offset: @offset, "member-id" => params["member-id"])

  # pagination
  @datacenters[:data] = pagination_helper(@datacenters[:data], @page, @datacenters.fetch(:meta, {}).fetch("total", 0))

  haml :'data-centers/index'
end

get '/data-centers/:id' do
  @datacenter = get_datacenters(id: params[:id])

  @works = get_works(query: params[:query], "publisher-id" => params[:id], offset: @offset, 'resource-type-id' => params['resource-type-id'], 'source-id' => params['source-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], sort: params[:sort])

  # check for existing claims if user is logged in
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user

  # pagination for works
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "data-centers"
  haml :'data-centers/show'
end

get '/members' do
  @members = get_members(query: params[:query], "member-type" => params["member-type"], region: params[:region], year: params[:year])

  haml :'members/index'
end

get '/members/:id' do
  @member = get_members(id: params[:id])

  @works = get_works(query: params[:query], "member-id" => params[:id], offset: @offset, 'resource-type-id' => params['resource-type-id'], 'publisher-id' => params['publisher-id'], 'year' => params['year'])

  # check for existing claims if user is logged in
  @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user

  # pagination for works
  @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))

  params[:model] = "members"
  haml :'members/show'
end

get '/sources' do
  @sources = get_sources(query: params[:query], "group-id" => params["group-id"])

  haml :'sources/index'
end

get '/sources/:id' do
  @source  = get_sources(id: params[:id])

  group_id = @source.fetch(:data, {}).fetch("attributes", {}).fetch("group-id", nil)

  if %w(relations results).include?(group_id)
    @works = get_works("source-id" => params[:id], offset: @offset, sort: params[:sort], 'relation-type-id' => params['relation-type-id'])

    # check for existing claims if user is logged in
    @works[:data] = get_claimed_items(current_user, @works.fetch(:data, [])) if current_user

    # pagination for works
    @works[:data] = pagination_helper(@works[:data], @page, @works.fetch(:meta, {}).fetch("total", 0))
  elsif group_id == "contributions"
    @contributions = get_contributions("source-id" => params[:id], "publisher-id" => params["publisher-id"], offset: @offset, rows: 25)

    # check for existing claims if user is logged in
    @contributions[:data] = get_claimed_items(current_user, @contributions.fetch(:data, [])) if current_user

    # pagination for contributions
    @contributions[:data] = pagination_helper(@contributions[:data], @page, @contributions.fetch(:meta, {}).fetch("total", 0))
  end

  params[:model] = "sources"
  haml :'sources/show'
end

get '/contributions' do
  @contributions = get_contributions(query: params[:query], "publisher-id" => params["publisher-id"], "source-id" => params["source-id"], offset: @offset)

  # pagination
  @contributions[:data] = pagination_helper(@contributions[:data], @page, @contributions.fetch(:meta, {}).fetch("total", 0))

  haml :'contributions/show'
end

get '/citation' do
  halt 422, json(status: 'error', message: 'DOI missing or wrong format.') unless params[:doi] && doi?(params[:doi])

  citation_format = settings.citation_formats.fetch(params[:format], nil)
  halt 415, json(status: 'error', message: 'Format missing or not supported.') unless citation_format

  # use doi content negotiation to get formatted citation
  result = Maremma.get "http://doi.org/#{params[:doi]}", content_type: citation_format

  # check for errors
  if result.fetch("errors", []).present?
    error = result.fetch('errors', []).first
    status = error.fetch('status', 400).to_i
    message = error.fetch('title', "An error occured.")
    halt status, json(status: 'error', message: message)
  elsif result["data"].blank?
    halt 404, json(status: 'error', message: 'Not found')
  end

  settings.ga.event('Citations', '/citation', citation_format, nil, true) if ENV['GABBA_COOKIE'] && ENV['RACK_ENV'] != "test"

  content_type citation_format + '; charset=utf-8'
  result.fetch("data", nil)
end

get '/heartbeat' do
  content_type 'text/html'

  'OK'
end
