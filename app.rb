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
  works = Array(result.fetch(:data, [])).select {|item| item["type"] == "works" }
  @meta = result.fetch(:meta, {})

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @works_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  # check for existing claims if user is logged in
  works = get_claimed_items(current_user, works) if current_user

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @sources = Array(result.fetch(:data, [])).select {|item| item["type"] == "sources" }

  params[:model] = "works"

  haml :'works/index'
end

get %r{/works/(.+)} do
  params["id"] = params[:captures].first

  # workaround, as nginx swallows double backslashes
  params["id"] = params["id"].gsub(/(http|https):\/+(\w+)/, '\1://\2')

  result = get_works(id: params["id"])
  work = result.fetch(:data, {})

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @work_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  elsif works.blank?
    @work_error = "Work \"#{params['id']}\" not found."
  end

  @publishers = Array(result.fetch(:included, [])).select {|item| item["type"] == "publishers" }
  @resource_types = Array(result.fetch(:included, [])).select {|item| item["type"] == "resource-types" }
  @work_types = Array(result.fetch(:included, [])).select {|item| item["type"] == "work-types" }
  @meta = result[:meta]

  # check for existing claims if user is logged in and work is registered with DataCite
  if current_user && works.first.fetch("attributes", {}).fetch("registration-agency-id", nil) == "datacite"
    @work = get_claimed_items(current_user, [work]).first
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_contributions("work-id" => params["id"], "source-id" => params["source-id"], offset: offset, rows: 100)
  @contributions= Array(collection.fetch(:data, [])
  @meta["contribution-total"] = collection.fetch(:meta, {}).fetch("total", 0)
  @meta["contribution-sources"] = collection.fetch(:meta, {}).fetch("sources", {})

  relations = get_relations("work-id" => params["id"], "source-id" => params["source-id"], "relation-type-id" => params["relation-type-id"], offset: offset, rows: 25)
  relations = Array(relations.fetch(:data, [])
  @meta["relation-total"] = relations.fetch(:meta, {}).fetch("total", 0)
  @meta["relation-types"] = relations.fetch(:meta, {}).fetch("relation-types", {})
  @meta["relation-sources"] = relations.fetch(:meta, {}).fetch("sources", {})
  @meta["relation-publishers"] = collection.fetch(:meta, {}).fetch("publishers", {})

  # check for existing claims if user is logged in
  works = get_claimed_items(current_user, relations) if current_user

  @relations = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["relation-total"]) do |pager|
    pager.replace relations
  end

  params[:model] = "works"

  haml :'works/show'
end

get '/contributors' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result = get_contributors(query: params[:query], offset: offset)
  contributors = Array(result.fetch(:data, []))
  @meta = result[:meta]

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @contributors_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

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
  @contributor = Array(result.fetch(:data, [])).find { |item| item["type"] == "contributors" }

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @contributor_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  elsif @contributor.blank?
    @contributor_error = "Contributor \"#{params['id']}\" not found."
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_contributions("contributor-id" => id, "source-id" => params["source-id"], offset: offset)
  contributions = Array(collection.fetch(:data, [])).select {|item| item["type"] == "contributions" }

  # check for existing claims if user is logged in
  contributions = get_claimed_items(current_user, contributions) if current_user

  @meta = collection[:meta]
  @contribution_sources = Array(collection.fetch(:data, [])).select {|item| item["type"] == "sources" }
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
  datacenters = Array(result.fetch(:data, [])).select {|item| item["type"] == "publishers" }

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @datacenters_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  @meta = result[:meta]

  @datacenters = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace datacenters
  end

  haml :'data-centers/index'
end

get '/data-centers/:id' do
  result = get_datacenters(id: params[:id])
  @datacenter = Array(result.fetch(:data, [])).find {|item| item["type"] == "publishers" }
  @members = Array(result.fetch(:data, [])).select {|item| item["type"] == "members" }

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @datacenter_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  elsif @datacenter.blank?
    @datacenter_error = "Data center \"#{params['id']}\" not found."
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_works(query: params[:query], "publisher-id" => params[:id], offset: offset, 'resource-type-id' => params['resource-type-id'], 'source-id' => params['source-id'], 'relation-type-id' => params['relation-type-id'], 'year' => params['year'], sort: params[:sort])
  works = Array(collection.fetch(:data, [])).select {|item| item["type"] == "works" }
  @meta = collection[:meta]

  # check for errors
  if collection.fetch(:errors, []).present?
    error = collection.fetch(:errors, []).first
    @works_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  # check for existing claims if user is logged in
  works = get_claimed_items(current_user, works) if current_user

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @resource_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "resource-types" }
  @relation_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "relation-types" }
  @work_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "work-types" }
  @sources = Array(collection.fetch(:data, [])).select {|item| item["type"] == "sources" }


  # Add Claim facet by Type of Source, commit: 45ece1be7f1f2a905c3e4780b7bc6e22e2e7f048
  # contributions = get_contributions("publisher-id" => params[:id], offset: offset, rows: 100)
  # @contributions = Array(contributions.fetch(:data, [])).select {|item| item["type"] == "contributions" }
  # @contribution_sources = Array(contributions.fetch(:data, [])).select {|item| item["type"] == "sources" }
  # @meta["contribution-total"] = contributions.fetch(:meta, {}).fetch("total", 0)
  # @meta["contribution-sources"] = contributions.fetch(:meta, {}).fetch("sources", {})


  params[:model] = "data-centers"

  haml :'data-centers/show'
end

get '/members' do
  result = get_members(query: params[:query], "member-type" => params["member-type"], region: params[:region], year: params[:year])
  @members = Array(result.fetch(:data, [])).select {|item| item["type"] == "members" }
  @meta = result[:meta]

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @members_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  haml :'members/index'
end

get '/members/:id' do
  result = get_members(id: params[:id])
  @member = result.fetch(:data, {})

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @member_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  elsif @member.blank?
    @member_error = "Member \"#{params['id']}\" not found."
  end

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  collection = get_works(query: params[:query], "member-id" => params[:id], offset: offset, 'resource-type-id' => params['resource-type-id'], 'publisher-id' => params['publisher-id'], 'year' => params['year'])
  works = Array(collection.fetch(:data, [])).select {|item| item["type"] == "works" }
  @meta = collection[:meta]

  # check for errors
  if collection.fetch(:errors, []).present?
    error = collection.fetch(:errors, []).first
    @works_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  # check for existing claims if user is logged in
  works = get_claimed_items(current_user, works) if current_user

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @resource_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "resource-types" }
  @publishers = []

  params[:model] = "members"

  haml :'members/show'
end

get '/sources' do
  result = get_sources(query: params[:query], "group-id" => params["group-id"])
  @sources = Array(result.fetch(:data, []))
  @meta = result[:meta]

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @sources_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  haml :'sources/index'
end

get '/sources/:id' do
  result = get_sources(id: params[:id])
  @source = result.fetch(:data, {})

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @source_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  elsif @source.blank?
    @source_error = "Source \"#{params['id']}\" not found."
  end

  @groups = Array(result.fetch(:included, [])).select {|item| item["type"] == "groups" }
  group = @groups.first

  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  if %w(relations results).include?(group["id"])
    collection = get_works("source-id" => params[:id], offset: offset, sort: params[:sort], 'relation-type-id' => params['relation-type-id'])
    works = Array(collection.fetch(:data, [])).select {|item| item["type"] == "works" }
    @sources = Array(collection.fetch(:data, [])).select {|item| item["type"] == "sources" }
    @relation_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "relation-types" }
    @work_types = Array(collection.fetch(:data, [])).select {|item| item["type"] == "work-types" }
    @meta = collection[:meta]

    # check for existing claims if user is logged in
    works = get_claimed_items(current_user, works) if current_user

    @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
      pager.replace works
    end
  elsif group["id"] == "contributions"
    collection = get_contributions("source-id" => params[:id], "publisher-id" => params["publisher-id"], offset: offset, rows: 25)
    contributions= Array(collection.fetch(:data, [])).select {|item| item["type"] == "contributions" }
    @contribution_sources = Array(collection.fetch(:data, [])).select {|item| item["type"] == "sources" }
    @contribution_publishers = Array(collection.fetch(:data, [])).select {|item| item["type"] == "publishers" }
    @meta = collection[:meta]
    @meta["contribution-total"] = collection.fetch(:meta, {}).fetch("total", 0)
    @meta["contribution-sources"] = collection.fetch(:meta, {}).fetch("sources", {})
    @meta["contribution-publishers"] = collection.fetch(:meta, {}).fetch("publishers", {}).sort_by(&:last).reverse.first 20

    # check for existing claims if user is logged in
    contributions = get_claimed_items(current_user, contributions) if current_user

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

get '/contributions' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result = get_contributions(query: params[:query], "publisher-id" => params["publisher-id"], "source-id" => params["source-id"], offset: offset)
  contributions = Array(result.fetch(:data, []))
  @meta = result[:meta]

  # check for errors
  if result.fetch(:errors, []).present?
    error = result.fetch(:errors, []).first
    @contributions_error = [error.fetch("status", ""), error.fetch("title", "")].join(" ")
  end

  @contributions = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace contributions
  end

  @meta["contribution-total"] = result.fetch(:meta, {}).fetch("total", 0)
  @meta["contribution-sources"] = result.fetch(:meta, {}).fetch("sources", {})

  haml :'contributions/show'
end
