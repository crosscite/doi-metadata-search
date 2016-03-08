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

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

get '/' do
  if params.empty?
    haml :splash, locals: { page: { query: '' } }
  else
    solr_result = select(search_query)

    page = {
      bare_sort: params['sort'],
      bare_query: bare_query,
      query_type: query_type,
      bare_filter: params['filter'],
      query: query_terms,
      facet_query: abstract_facet_query,
      page: query_page,
      rows: {
        options: TYPICAL_ROWS,
        actual: query_rows
      },
      items: search_results(solr_result),
      paginate: Paginate.new(query_page, query_rows, solr_result),
      facets: facet_results(solr_result) }

    unless page[:items].length > 0
      page = get_alt_result(page)
      redirect to(page[:alt_url]) if page[:alt_text] =~ /^DOI found/
    end

    haml :results, locals: { page: page }
  end
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
  redirect to('/')
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

  result = Maremma.post "#{ENV['JWT_HOST']}/api/claims", data: claim, token: params['api_key']

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
