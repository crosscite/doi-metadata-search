require 'dotenv'
Dotenv.load

require_relative 'lib/version'

# optionally use Bugsnag for error logging
if ENV['BUGSNAG_KEY']
  require 'bugsnag'
  Bugsnag.configure do |config|
    config.api_key = ENV['BUGSNAG_KEY']
    config.project_root = "/var/www/#{ENV['APPLICATION']}/shared"
    config.app_version = App::VERSION
  end
end

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/json'
require 'active_support/all'
require 'json'
require 'rsolr'
require 'mongo'
require 'haml'
require 'will_paginate'
require 'cgi'
require 'faraday'
require 'faraday_middleware'
require 'faraday/encoding'
require 'haml'
require 'gabba'
require 'rack-session-mongo'
require 'rack-flash'
require 'omniauth-orcid'
require 'oauth2'
require 'resque'
require 'open-uri'
require 'uri'

Dir[File.join(File.dirname(__FILE__), 'lib', '*.rb')].each { |f| require f }

if ENV['BUGSNAG_KEY']
  use Bugsnag::Rack
  enable :raise_errors
end

require 'log4r'
include Log4r
logger = Log4r::Logger.new('test')
logger.trace = true
logger.level = ENV['LOG_LEVEL'].upcase.constantize

formatter = Log4r::PatternFormatter.new(pattern: '[%l] %t  %M')
Log4r::Logger['test'].outputters << Log4r::Outputter.stdout
Log4r::Logger['test'].outputters << Log4r::FileOutputter.new('logtest',
                                                             filename: 'log/app.log',
                                                             formatter: formatter)

# logger.datetime_format = "%Y-%m-%d %H:%M:%S"
# root_dir = ::File.dirname(__FILE__)
# logger.debug "root = #{root_dir}"
# logger.formatter = proc do |severity, datetime, progname, msg|
#  filename = Kernel.caller[4].gsub(root_dir+'/', '')
#  filename = filename.gsub(/\:in.+/, '')
#  "#{datetime} #{severity} -- #{filename}: #{msg}\n"
# end
use Rack::Logger, logger

MIN_MATCH_SCORE = 2
MIN_MATCH_TERMS = 3
MAX_MATCH_TEXTS = 1000

FACET = true
HIGHLIGHTING = false
TYPICAL_ROWS = [10, 20, 50, 100, 500]
DEFAULT_ROWS = 20
MONTH_SHORT_NAMES = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

ORCID_VERSION = '1.2'

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

configure do
  set :logging, Logger::INFO

  # Work around rack protection referrer bug
  set :protection, except: :json_csrf

  # Configure solr
  set :solr, RSolr.connect(url: ENV['SOLR_URL'])

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

  # Set up for http requests to data.datacite.org and dx.doi.org
  dx_doi_org = Faraday.new(url: 'http://doi.org') do |c|
    c.use FaradayMiddleware::FollowRedirects, limit: 5
    c.response :encoding
    c.adapter Faraday.default_adapter
  end

  data_service = Faraday.new(url: 'http://data.datacite.org') do |c|
    c.response :encoding
    c.adapter Faraday.default_adapter
  end

  set :dx_doi_org, dx_doi_org
  set :data_service, data_service

  # Citation format types
  set :citation_formats,
      'bibtex' => 'application/x-bibtex',
      'ris' => 'application/x-research-info-systems',
      'apa' => 'text/x-bibliography; style=apa',
      'harvard' => 'text/x-bibliography; style=harvard1',
      'ieee' => 'text/x-bibliography; style=ieee',
      'mla' => 'text/x-bibliography; style=modern-language-association',
      'vancouver' => 'text/x-bibliography; style=vancouver',
      'chicago' => 'text/x-bibliography; style=chicago-fullnote-bibliography'

  # Set facet fields
  set :facet_fields, %w(resourceType_facet publicationYear_facet publisher_facet)

  # Google analytics event tracking
  set :ga, Gabba::Gabba.new(ENV['GABBA_COOKIE'], ENV['GABBA_URL']) if ENV['GABBA_COOKIE']

  # ORCID endpoint
  orcid_service = Faraday.new(url: ENV['ORCID_API_URL']) do |c|
    c.response :encoding
    c.adapter Faraday.default_adapter
  end

  set :orcid_service, orcid_service

  # Orcid oauth2 object we can use to make API calls
  set :orcid_oauth, OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                       ENV['ORCID_CLIENT_SECRET'],
                                       site: ENV['ORCID_API_URL'])

  # Set up session and auth middlewares for ORCiD sign in
  use Rack::Session::Mongo, settings.mongo[ENV['DB_NAME']]
  use Rack::Flash
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

  OmniAuth.config.logger = logger

  set :show_exceptions, true
end

get '/' do
  if !params.key?('q') || !query_terms
    haml :splash, locals: { page: { query: '' } }
  else
    params['q'] = session[:orcid][:uid] if signed_in? && !params.key?('q')
    solr_result = select search_query

    page = {
      bare_sort: params['sort'],
      bare_query: params['q'],
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
      facets: !solr_result['facet_counts'].nil? ? solr_result['facet_counts']['facet_fields']
                                                   : {}
    }

    unless page[:items].length > 0
      page[:alt_url] = "http://search.crossref.org/?q=#{params['q']}"
      page[:alt_text] = get_alt_text(page)
    end

    haml :results, locals: { page: page }
  end
end

get '/help/examples' do
  haml :examples_help, locals: { page: { query: '' } }
end

get '/help/status' do
  haml :status_help, locals: { page: { query: '', stats: index_stats } }
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

  if signed_in? && params['doi']
    doi = params['doi']
    plain_doi = to_doi(doi)
    orcid_record = settings.orcids.find_one(orcid: sign_in_id)
    already_added = !orcid_record.nil? && orcid_record['locked_dois'].include?(plain_doi)

    if already_added
      status = 'ok'
    else
      # TODO escape DOI characters
      params = {
        q: "doi:\"#{doi}\"",
        fl: '*'
      }
      result = settings.solr.paginate 0, 1, ENV['SOLR_SELECT'], params: params
      doi_record = result['response']['docs'].first

      if !doi_record
        status = 'no_such_doi'
      else
        if OrcidClaim.perform(session_info, doi_record)
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
          OrcidUpdate.perform(session_info)
          updated_orcid_record = settings.orcids.find_one(orcid: sign_in_id)

          if updated_orcid_record['dois'].include?(plain_doi)
            status = 'ok_visible'
          else
            status = 'ok'
          end
        else
          status = 'oauth_timeout'
        end
      end
    end
  end

  content_type 'application/json'
  { status: status }.to_json
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
    if OrcidUpdate.perform(session_info)
      status = 'ok'
    else
      status = 'oauth_timeout'
    end
  end

  content_type 'application/json'
  { status: status }.to_json
end

get '/citation' do
  halt 422, json(status: 'error', message: 'DOI missing or wrong format.') unless params[:doi] && doi?(params[:doi])

  citation_format = settings.citation_formats.fetch(params[:format], nil)
  halt 415, json(status: 'error', message: 'Format missing or not supported.') unless citation_format

  response = settings.data_service.get do |req|
    req.url "/#{params[:doi]}"
    req.headers['Accept'] = citation_format
  end

  body = force_utf8(response.body)

  halt response.status, json(status: 'error', message: body) unless response.success?

  settings.ga.event('Citations', '/citation', citation_format, nil, true) if ENV['GABBA_COOKIE']

  content_type citation_format + '; charset=utf-8'
  body
end

get '/auth/orcid/callback' do
  session[:orcid] = request.env['omniauth.auth']
  Resque.enqueue(OrcidUpdate, session_info)
  update_profile
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

get '/heartbeat' do
  content_type 'application/json'

  params['q'] = 'fish'

  begin
    # Attempt a query with solr
    solr_result = select(search_query)

    # Attempt some queries with mongo
    result_list = search_results(solr_result)

    { status: :ok }.to_json
  rescue StandardError => e
    { status: :error, type: e.class, message: e }.to_json
  end
end
