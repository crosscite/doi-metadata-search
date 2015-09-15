begin
  # requires dotenv plugin/gem
  require 'dotenv'

  # make sure DOTENV is set, defaults to "default"
  ENV['DOTENV'] ||= 'default'

  # load ENV variables from file specified by DOTENV
  # use .env with DOTENV=default
  filename = ENV['DOTENV'] == 'default' ? '.env' : ".env.#{ENV['DOTENV']}"
  Dotenv.load! File.expand_path("../#{filename}", __FILE__)
rescue Errno::ENOENT
  $stderr.puts "Please create #{filename} file, or use DOTENV=example for example configuration"
  exit
end

# Check for required ENV variables, can be set in .env file
# ENV_VARS is hash of required ENV variables
env_vars = %w(HOSTNAME SERVERS SITENAME SOLR_URL ORCID_CLIENT_ID ORCID_CLIENT_SECRET ORCID_URL ORCID_API_URL)
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
DEFAULT_TIMEOUT = 60

require 'sinatra'
require 'sinatra/json'
require 'sinatra/config_file'
require 'active_support/all'
require 'rsolr'
require 'mongo'
require 'haml'
require 'will_paginate'
require 'will_paginate-bootstrap'
require 'cgi'
require 'faraday'
require 'faraday_middleware'
require 'faraday/encoding'
require 'gabba'
require 'rack-flash'
require 'omniauth-orcid'
require 'sidekiq'
require 'sidekiq/api'
require 'open-uri'
require 'uri'

NETWORKABLE_EXCEPTIONS = [Faraday::ClientError,
                          Faraday::TimeoutError,
                          URI::InvalidURIError,
                          Encoding::UndefinedConversionError,
                          ArgumentError,
                          NoMethodError,
                          TypeError]

Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), 'lib', ENV['RA'], '*.rb')].each { |f| require f }

config_file "config/#{ENV['RA']}.yml"

configure do
  set :root, File.dirname(__FILE__)

  # Configure logging
  enable :logging
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true
  use Rack::CommonLogger, file

  # Configure sessions and flash
  enable :sessions
  use Rack::Flash

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Configure solr
  set :solr, RSolr.connect(url: ENV['SOLR_URL'])

  # Configure ORCID client, scope and site are different from defaults
  use OmniAuth::Builder do
    provider :orcid, ENV['ORCID_CLIENT_ID'], ENV['ORCID_CLIENT_SECRET'],
      authorize_params: {
        scope: '/orcid-profile/read-limited /orcid-works/create'
      },
      client_options: {
        site: ENV['ORCID_API_URL'],
        authorize_url: "#{ENV['ORCID_URL']}/oauth/authorize",
        token_url: "#{ENV['ORCID_API_URL']}/oauth/token"
      },
      provider_ignores_state: true
  end
  # OmniAuth.config.logger = logger

  # Configure mongo
  set :mongo, Mongo::Connection.new(ENV['DB_HOST'])
  set :dois, settings.mongo[ENV['DB_NAME']]['dois']
  set :shorts, settings.mongo[ENV['DB_NAME']]['shorts']
  set :issns, settings.mongo[ENV['DB_NAME']]['issns']
  set :citations, settings.mongo[ENV['DB_NAME']]['citations']
  set :patents, settings.mongo[ENV['DB_NAME']]['patents']
  set :claims, settings.mongo[ENV['DB_NAME']]['claims']
  set :orcids, settings.mongo[ENV['DB_NAME']]['orcids']
  set :links, settings.mongo[ENV['DB_NAME']]['links']

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

  set :show_exceptions, true

  # optionally use Bugsnag for error logging
  if ENV['BUGSNAG_KEY']
    require 'bugsnag'
    Bugsnag.configure do |config|
      config.api_key = ENV['BUGSNAG_KEY']
      config.project_root = settings.root
      config.app_version = App::VERSION
      config.release_stage = ENV['RACK_ENV']
      config.notify_release_stages = ["production", "development"]
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
  result = get_result("http://doi.org/#{params[:doi]}", content_type: citation_format)

  halt result["status"], json(status: 'error', message: response["error"]) if result["error"]

  settings.ga.event('Citations', '/citation', citation_format, nil, true) if ENV['GABBA_COOKIE'] && ENV['RACK_ENV'] != "test"

  content_type citation_format + '; charset=utf-8'
  result
end

get '/help/examples' do
  haml :examples_help, locals: { page: { query: '' } }
end

get '/help/stats' do
  haml :stats_help, locals: { page: { query: '', stats: stats } }
end

get '/auth/orcid/callback' do
  session[:orcid] = request.env.fetch('omniauth.auth', nil)
  UpdateJob.perform_async(session[:orcid])

  haml :auth_callback
end

# Used to sign out a user but can also be used to mark that a user has seen the
# 'You have been signed out' message. Clears the user's session cookie.
get '/auth/signout' do
  session.clear
  redirect(params[:redirect_uri])
end

get '/auth/failure' do
  flash[:error] = "Authentication failed with message \"#{params['message']}\"."
  haml :auth_callback
end

get '/auth/orcid/deauthorized' do
  haml 'ORCID has deauthorized this app.'
end

get '/orcid/activity' do
  if signed_in?
    haml :activity, locals: { page: { query: '' } }
  else
    redirect '/'
  end
end

get '/orcid/claim' do
  status = 'oauth_timeout'
  message = nil

  if signed_in? && params['doi']
    doi = params['doi']
    plain_doi = to_doi(doi)
    orcid_record = settings.orcids.find_one({:orcid => sign_in_id})
    already_added = !orcid_record.nil? && orcid_record['locked_dois'].include?(plain_doi)

    if already_added
      status = 'ok'
    else
      # TODO escape DOI characters
      params = {
        q: "doi:\"#{doi}\"",
        fl: '*'
      }
      result = settings.solr.paginate(0, 1, ENV['SOLR_SELECT'], params: params)
      doi_record = result['response']['docs'].first

      if !doi_record
        status = 'no_such_doi'
      else
        if ClaimJob.new.perform(session_info, doi_record)
          if orcid_record
            orcid_record['updated'] = true
            orcid_record['locked_dois'] << plain_doi
            orcid_record['locked_dois'].uniq!
            settings.orcids.save(orcid_record)
          else
            doc = { orcid: sign_in_id, dois: [], locked_dois: [plain_doi] }
            settings.orcids.insert(doc)
          end

          # The work could have been added as limited or public. If so we need
          # to tell the UI.
          UpdateJob.new.perform(session_info)
          updated_orcid_record = settings.orcids.find_one({ orcid: sign_in_id })

          if updated_orcid_record['dois'].include?(plain_doi)
            status = 'ok_visible'
          else
            status = 'ok'
          end
        else
          status = 'error'
          message = "An error ocucc."
        end
      end
    end
  end

  content_type 'application/json'
  { status: status, message: message }.to_json
end

get '/orcid/unclaim' do
  if signed_in? && params['doi']
    doi = params['doi']

    logger.info "Initiating unclaim for #{doi}"
    orcid_record = settings.orcids.find_one(orcid: sign_in_id)

    if orcid_record
      orcid_record['locked_dois'].delete(doi)
      settings.orcids.save(orcid_record)
    end
  end

  content_type 'application/json'
  { status: 'ok' }.to_json
end

get '/orcid/sync' do
  status = 'oauth_timeout'

  if signed_in?
    if UpdateJob.perform_async(session_info)
      status = 'ok'
    else
      status = 'oauth_timeout'
    end
  end

  content_type 'application/json'
  { status: status }.to_json
end
