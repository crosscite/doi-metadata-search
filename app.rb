begin
  # load ENV variables from .env file, requires dotenv gem
  require 'dotenv'
  Dotenv.load! File.expand_path("../.env", __FILE__)
rescue Errno::ENOENT
  $stderr.puts "Please create .env file, e.g. from .env.example"
  exit
end

# Check for required ENV variables, can be set in .env file
# ENV_VARS is hash of required ENV variables
env_vars = %w(HOSTNAME SOLR_URL)
env_vars.each { |env| fail ArgumentError,  "ENV[#{env}] is not set" unless ENV[env] }
ENV_VARS = Hash[env_vars.map { |env| [env, ENV[env]] }]

# Constants
MIN_MATCH_SCORE = 2
MIN_MATCH_TERMS = 3
MAX_MATCH_TEXTS = 1000
TYPICAL_ROWS = [10, 20, 50, 100, 500]
DEFAULT_ROWS = 20
MONTH_SHORT_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
ORCID_VERSION = '1.2'

require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'active_support/all'
require 'rsolr'
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
Dir[File.join(File.dirname(__FILE__), 'lib', ENV['RA'], '*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

configure do
  set :root, File.dirname(__FILE__)

  # Configure sessions and flash
  set :sessions, key: ENV['SESSION_KEY']
  use Rack::Flash

  # Configure logging
  Dir.mkdir('log') unless File.exists?('log')

  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Configure solr
  set :solr, RSolr.connect(url: ENV['SOLR_URL'])

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
      config.notify_release_stages = %w(production, development)
    end

    use Bugsnag::Rack
    enable :raise_errors
  end
end

before do
  @params = params
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

  result = get_works(q: params[:q], offset: offset, 'publisher-id' => params['publisher-id'])
  works = result[:data].select {|item| item["type"] == "works" }
  @meta = result[:meta]

  # check for existing claims if user is logged in
  works = get_claims(current_user, works) if current_user

  @works = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace works
  end

  @publishers = result[:data].select {|item| item["type"] == "publishers" }

  haml :'works/index'
end

get '/works/:id' do
  work = get_works(id: params[:id])

  # check for existing claims if user is logged in
  #works[:data] = get_claims(current_user, works[:data]) if current_user

  haml :'works/show'
end

get '/relations' do
  # contributors = get_contributors(q: params[:q])
  # haml :contributors, locals: { data: contributors[:data], meta: contributors[:meta], params: params }
end

get '/contributors' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result = get_contributors(q: params[:q], offset: offset)
  contributors = result[:data]
  @meta = result[:meta]

  @contributors = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace contributors
  end

  haml :'contributors/index'
end

get '/contributors/:id' do
  id = "orcid.org/" + params[:id]
  result = get_contributors(id: id)
  @contributor = result[:data]
  @meta = result[:meta]

  haml :'contributors/show'
end

get '/data-centers' do
  page = params.fetch('page', 1).to_i
  offset = DEFAULT_ROWS * (page - 1)

  result  = get_datacenters(q: params[:q], offset: offset)
  datacenters = result[:data]
  @meta = result[:meta]

  @datacenters = WillPaginate::Collection.create(page, DEFAULT_ROWS, @meta["total"]) do |pager|
    pager.replace datacenters
  end

  haml :'data-centers/index'
end

get '/data-centers/:id' do
  result = get_datacenters(id: params[:id])
  @datacenter = result[:data]
  @meta = result[:meta]

  haml :'data-centers/show'
end

get '/members' do
  result = get_members(q: params[:q], "member-type" => params["member-type"], region: params[:region], year: params[:year])
  @members = result[:data].select {|item| item["type"] == "members" }
  @meta = result[:meta]

  haml :'members/index'
end

get '/members/:id' do
  result = get_members(id: params[:id])
  @member = result[:data]
  @meta = result[:meta]

  haml :'members/show'
end

get '/citation' do
  halt 422, json(status: 'error', message: 'DOI missing or wrong format.') unless params[:doi] && doi?(params[:doi])

  citation_format = settings.citation_formats.fetch(params[:format], nil)
  halt 415, json(status: 'error', message: 'Format missing or not supported.') unless citation_format

  # use doi content negotiation to get formatted citation
  result = Maremma.get "http://doi.org/#{params[:doi]}", content_type: citation_format

  halt result.fetch('errors', {}).fetch('status', 400).to_i, json(result) if result["errors"]

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

  halt 503, 'failed' unless services_up?

  'OK'
end
