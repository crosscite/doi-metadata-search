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
ENV['SESSION_KEY'] ||= "_#{ENV['APPLICATION']}_session"
ENV['SESSION_DOMAIN'] ||= ""
ENV['SECRET_KEY_BASE'] ||= SecureRandom.hex(15)
ENV['SITENAMELONG'] ||= "DataCite Search"
ENV['LOG_LEVEL'] ||= "info"
ENV['RA'] ||= "datacite"
ENV['API_URL'] ||= "http://api.datacite.org"

env_vars = %w(SITENAMELONG LOG_LEVEL RA API_URL SESSION_KEY SECRET_KEY_BASE)
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
require 'tilt/haml'
require 'haml'
require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate-bootstrap'
require 'cgi'
require 'maremma'
require 'gabba'
require 'rack-flash'
require 'omniauth/jwt'
require 'open-uri'
require 'uri'

Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

configure do
  set :root, File.dirname(__FILE__)

  # Configure sessions and flash
  use Rack::Session::Cookie, key: ENV['SESSION_KEY'],
                             domain: ENV['SESSION_DOMAIN'],
                             secret: ENV['SECRET_KEY_BASE']
  use Rack::Flash

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Set Logger
  set :logger, Logger.new(STDOUT)

  # Configure omniauth client
  use OmniAuth::Builder do
    provider :jwt, ENV['JWT_SECRET_KEY'],
      auth_url: "#{ENV['JWT_HOST']}/services/#{ENV['JWT_NAME']}",
      uid_claim: 'uid',
      required_claims: ['uid', 'name'],
      info_map: { "name" => "name",
                  "api_key" => "api_key",
                  "role" => "role" }
  end
  # OmniAuth.config.logger = logger

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

  # optionally use Bugsnag for error logging
  if ENV['BUGSNAG_KEY']
    require 'bugsnag'
    Bugsnag.configure do |config|
      config.api_key = ENV['BUGSNAG_KEY']
      config.project_root = settings.root
      config.app_version = App::VERSION
      config.release_stage = ENV['RACK_ENV']
      config.notify_release_stages = %w(production development)
    end

    use Bugsnag::Rack
    enable :raise_errors
  end
end

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/' do
  @meta = { page: "splash" }

  haml :splash
end

get '/works' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result = get_works(query: params[:query], offset: offset, 'publisher-id' => params['publisher-id'], 'resource-type-id' => params['resource-type-id'], 'year' => params['year'])
  works = result[:data].select {|item| item["type"] == "works" }
  @meta = result[:meta]

  # check for existing claims if user is logged in
  works = get_claims(current_user, works) if current_user

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @resource_types = Array(result[:data]).select {|item| item["type"] == "resource-types" }
  @publishers = Array(result[:data]).select {|item| item["type"] == "publishers" }
  @sources = Array(result[:data]).select {|item| item["type"] == "sources" }
  @work_types = Array(result[:data]).select {|item| item["type"] == "work-types" }

  params[:model] = "works"

  haml :'works/index'
end

get %r{/works/(.+)} do
  params["id"] = params[:captures].first

  # workaround, as nginx swallows double backslashes
  params["id"] = params["id"].gsub(/(http|https):\/+(\w+)/, '\1://\2')

  result = get_works(id: params["id"])
  works = result[:data].select {|item| item["type"] == "works" }

  unless works.present?
    flash[:error] = "Work \"#{params['id']}\" not found."
    redirect to('/works')
  end

  @publishers = Array(result[:data]).select {|item| item["type"] == "publishers" }
  @members = Array(result[:data]).select {|item| item["type"] == "members" }
  @sources = Array(result[:data]).select {|item| item["type"] == "sources" }
  @work_types = Array(result[:data]).select {|item| item["type"] == "work-types" }
  @meta = result[:meta]

  # check for existing claims if user is logged in and work is registered with DataCite
  if current_user && works.first.fetch("attributes", {}).fetch("registration-agency-id", nil) == "datacite"
    works = get_claims(current_user, works)
  end

  @work = works.first

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_contributions("work-id" => params["id"], "source-id" => params["source-id"], offset: offset, rows: 100)
  @contributions= Array(collection[:data]).select {|item| item["type"] == "contributions" }
  @contribution_sources = Array(collection[:data]).select {|item| item["type"] == "sources" }
  @meta["contribution-total"] = collection.fetch(:meta, {}).fetch("total", 0)
  @meta["contribution-sources"] = collection.fetch(:meta, {}).fetch("sources", {})

  relations = get_relations("work-id" => params["id"], "source-id" => params["source-id"], "relation-type-id" => params["relation-type-id"], offset: offset, rows: 25)
  @relation_sources = Array(relations[:data]).select {|item| item["type"] == "sources" }
  @relation_types = Array(relations[:data]).select {|item| item["type"] == "relation-types" }
  @meta["relation-total"] = relations.fetch(:meta, {}).fetch("total", 0)
  @meta["relation-types"] = relations.fetch(:meta, {}).fetch("relation-types", {})
  @meta["relation-sources"] = relations.fetch(:meta, {}).fetch("sources", {})

  @relations= Array(relations[:data]).select {|item| item["type"] == "relations" }

  # check for existing claims if user is logged in
  @relations = get_claims(current_user, @relations) if current_user

  @relations = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["relation-total"]) do |pager|
    pager.replace @relations
  end

  params[:model] = "works"

  haml :'works/show'
end

get '/contributors' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result = get_contributors(query: params[:query], offset: offset)
  contributors = result[:data]
  @meta = result[:meta]

  @contributors = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace contributors
  end

  haml :'contributors/index'
end

get '/contributors/:id' do
  if validate_orcid(params[:id])
    id = "orcid.org/#{params[:id]}"
  else
    id = "https://github.com/#{params[:id]}"
  end
  result = get_contributors(id: id)
  @contributor = result[:data].find { |item| item["type"] == "contributors" }

  unless @contributor.present?
    flash[:error] = "Contributor \"#{params['id']}\" not found."
    redirect to('/contributors')
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_contributions("contributor-id" => id, "source-id" => params["source-id"], offset: offset)
  contributions = Array(collection[:data]).select {|item| item["type"] == "contributions" }
  @meta = collection[:meta]
  @contribution_sources = Array(collection[:data]).select {|item| item["type"] == "sources" }
  @meta["contribution-total"] = collection.fetch(:meta, {}).fetch("total", 0)
  @meta["contribution-sources"] = collection.fetch(:meta, {}).fetch("sources", {})
  @contributions = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace contributions
  end

  params[:model] = "contributors"

  haml :'contributors/show'
end

get '/data-centers' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result  = get_datacenters(query: params[:query], offset: offset, "member-id" => params["member-id"])
  datacenters = Array(result[:data]).select {|item| item["type"] == "publishers" }
  @members = Array(result[:data]).select {|item| item["type"] == "members" }

  @meta = result[:meta]

  @datacenters = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace datacenters
  end

  haml :'data-centers/index'
end

get '/data-centers/:id' do
  result = get_datacenters(id: params[:id])
  @datacenter = Array(result[:data]).find {|item| item["type"] == "publishers" }
  @members = Array(result[:data]).select {|item| item["type"] == "members" }

  unless @datacenter.present?
    flash[:error] = "Data center \"#{params['id']}\" not found."
    redirect to('/data-centers')
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_works(query: params[:query], "publisher-id" => params[:id], offset: offset, 'resource-type-id' => params['resource-type-id'], 'source-id' => params['source-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], sort: params[:sort])
  works = Array(collection[:data]).select {|item| item["type"] == "works" }
  @meta = collection[:meta]

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @resource_types = Array(collection[:data]).select {|item| item["type"] == "resource-types" }
  @relation_types = Array(collection[:data]).select {|item| item["type"] == "relation-types" }
  @work_types = Array(collection[:data]).select {|item| item["type"] == "work-types" }
  @sources = Array(collection[:data]).select {|item| item["type"] == "sources" }

  params[:model] = "data-centers"

  haml :'data-centers/show'
end

get '/members' do
  result = get_members(query: params[:query], "member-type" => params["member-type"], region: params[:region], year: params[:year])
  @members = result[:data].select {|item| item["type"] == "members" }
  @meta = result[:meta]

  haml :'members/index'
end

get '/members/:id' do
  result = get_members(id: params[:id])
  @member = result[:data]

  unless @member.present?
    flash[:error] = "Member \"#{params['id']}\" not found."
    redirect to('/members')
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_works(query: params[:query], "member-id" => params[:id], offset: offset, 'resource-type-id' => params['resource-type-id'], 'publisher-id' => params['publisher-id'], 'year' => params['year'])
  works = collection[:data].select {|item| item["type"] == "works" }
  @meta = collection[:meta]

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @resource_types = Array(collection[:data]).select {|item| item["type"] == "resource-types" }
  @publishers = []

  params[:model] = "members"

  haml :'members/show'
end

get '/sources' do
  result = get_sources(query: params[:query], "group-id" => params["group-id"])
  @sources = Array(result[:data]).select {|item| item["type"] == "sources" }
  @groups = Array(result[:data]).select {|item| item["type"] == "groups" }
  @meta = result[:meta]

  haml :'sources/index'
end

get '/sources/:id' do
  result = get_sources(id: params[:id])
  @source = result[:data].find {|item| item["type"] == "sources" }

  unless @source.present?
    flash[:error] = "Source \"#{params['id']}\" not found."
    redirect to('/sources')
  end

  @groups = Array(result[:data]).select {|item| item["type"] == "groups" }
  group = @groups.first

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  if %w(relations results).include?(group["id"])
    collection = get_works("source-id" => params[:id], offset: offset, sort: params[:sort], 'relation-type-id' => params['relation-type-id'])
    works = Array(collection[:data]).select {|item| item["type"] == "works" }
    @sources = Array(collection[:data]).select {|item| item["type"] == "sources" }
    @relation_types = Array(collection[:data]).select {|item| item["type"] == "relation-types" }
    @work_types = Array(collection[:data]).select {|item| item["type"] == "work-types" }
    @meta = collection[:meta]

    @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
      pager.replace works
    end
  elsif group["id"] == "contributions"
    collection = get_contributions("source-id" => params[:id], offset: offset, rows: 25)
    contributions= Array(collection[:data]).select {|item| item["type"] == "contributions" }
    @contribution_sources = Array(collection[:data]).select {|item| item["type"] == "sources" }
    @meta = collection[:meta]
    @meta["contribution-total"] = collection.fetch(:meta, {}).fetch("total", 0)
    @meta["contribution-sources"] = collection.fetch(:meta, {}).fetch("sources", {})

    @contributions = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["contribution-total"]) do |pager|
      pager.replace contributions
    end
  else
    @meta = {}
  end

  params[:model] = "sources"

  haml :'sources/show'
end

get '/citation' do
  halt 422, json(status: 'error', message: 'DOI missing or wrong format.') unless params[:doi] && doi?(params[:doi])

  citation_format = settings.citation_formats.fetch(params[:format], nil)
  halt 415, json(status: 'error', message: 'Format missing or not supported.') unless citation_format

  # use doi content negotiation to get formatted citation
  result = Maremma.get "http://doi.org/#{params[:doi]}", content_type: citation_format

  if result["errors"]
    error = result.fetch('errors', [{}]).first
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

get '/auth/:service/callback' do
  session[:auth] = request.env['omniauth.auth']
  redirect to request.env['omniauth.origin'] || params[:origin] || '/'
end

get '/auth/signout' do
  session.clear
  redirect to("#{ENV['JWT_HOST']}/sign_out?id=#{ENV['JWT_NAME']}")
end

get '/auth/failure' do
  flash[:error] = "Authentication failed with message \"#{params['message']}\"."
  redirect to('/')
end

get '/orcid/claim' do
  content_type 'application/json'

  halt 401, json("errors" => [{ "title" => "Unauthorized.", "status" => 401 }]) unless params['api_key'].present?
  halt 422, json("errors" => [{ "title" => "Unprocessable entity.", "status" => 422 }]) unless params['orcid'].present? && params['doi'].present?

  claim = { "claim" => { "orcid" => params['orcid'],
                         "doi" =>  params['doi'],
                         "source_id" => "orcid_search" }}

  result = Maremma.post "#{ENV['ORCID_UPDATE_URL']}/api/claims", data: claim, token: params['api_key']

  if result.fetch('errors', []).present?
    json(result.fetch('errors', []).first)
  else
    status = result.fetch('data', {}).fetch('attributes', {}).fetch('state', 'none')
    json({ 'status' => status })
  end
end

get '/heartbeat' do
  content_type 'text/html'

  'OK'
end
