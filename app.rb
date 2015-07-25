require 'dotenv'
Dotenv.load

# optionally use sentry for error logging
if ENV['SENTRY_DSN']
  require 'raven'
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
    # config.environments = %w[staging production]
  end
end

require 'sinatra'
require 'sinatra/config_file'
require 'active_support/all'
require 'json'
require 'rsolr'
require 'mongo'
require 'haml'
require 'will_paginate'
require 'cgi'
require 'faraday'
require 'faraday_middleware'
require 'haml'
require 'gabba'
require 'rack-session-mongo'
require 'rack-flash'
require 'omniauth-orcid'
require 'oauth2'
require 'resque'
require 'open-uri'
require 'uri'
#require 'ap'

require 'log4r'
include Log4r
logger = Log4r::Logger.new('test')
logger.trace = true
logger.level = ENV['LOG_LEVEL'].upcase.constantize

formatter = Log4r::PatternFormatter.new(:pattern => "[%l] %t  %M")
Log4r::Logger['test'].outputters << Log4r::Outputter.stdout
Log4r::Logger['test'].outputters << Log4r::FileOutputter.new('logtest',
                                              :filename =>  'log/app.log',
                                              :formatter => formatter)
logger.info 'got log4r set up'
logger.debug "This is a message with level DEBUG"
logger.info "This is a message with level INFO"


#logger.datetime_format = "%Y-%m-%d %H:%M:%S"
#root_dir = ::File.dirname(__FILE__)
#logger.debug "root = #{root_dir}"
#logger.formatter = proc do |severity, datetime, progname, msg|
#  filename = Kernel.caller[4].gsub(root_dir+'/', '')
#  filename = filename.gsub(/\:in.+/, '')
#  "#{datetime} #{severity} -- #{filename}: #{msg}\n"
#end
use Rack::Logger, logger

require_relative 'lib/helpers'
require_relative 'lib/paginate'
require_relative 'lib/result'
require_relative 'lib/bootstrap'
require_relative 'lib/doi'
require_relative 'lib/session'
require_relative 'lib/data'
require_relative 'lib/orcid_update'
require_relative 'lib/orcid_claim'

MIN_MATCH_SCORE = 2
MIN_MATCH_TERMS = 3
MAX_MATCH_TEXTS = 1000

FACET = false
HIGHLIGHTING = false
TYPICAL_ROWS = [10, 20, 50, 100, 500]
DEFAULT_ROWS = 20
MONTH_SHORT_NAMES = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

after do
  response.headers['Access-Control-Allow-Origin'] = '*'
end

configure do
  set :logging, Logger::INFO

  # Work around rack protection referrer bug
  set :protection, :except => :json_csrf

  # Configure solr
  logger.info "Configuring Solr to connect to #{ENV['SOLR_URL']}"
  set :solr, RSolr.connect(url: ENV['SOLR_URL'])

  # Configure mongo
  set :mongo, Mongo::Connection.new(ENV['DB_HOST'])
  logger.info "Configuring Mongo: url=#{ENV['DB_HOST']}"
  set :dois, ENV['DB_NAME']['dois']
  set :shorts, ENV['DB_NAME']['shorts']
  set :issns, ENV['DB_NAME']['issns']
  set :citations, ENV['DB_NAME']['citations']
  set :patents, ENV['DB_NAME']['patents']
  set :claims, ENV['DB_NAME']['claims']
  set :orcids, ENV['DB_NAME']['orcids']
  set :links, ENV['DB_NAME']['links']

  # Set up for http requests to data.datacite.org and dx.doi.org
  dx_doi_org = Faraday.new(:url => 'http://doi.org') do |c|
    c.use FaradayMiddleware::FollowRedirects, :limit => 5
    c.adapter :net_http
  end

  set :data_service, Faraday.new(:url => 'http://data.datacite.org')
  set :dx_doi_org, dx_doi_org

  # Citation format types
  set :citation_formats, {
    'bibtex' => 'application/x-bibtex',
    'ris' => 'application/x-research-info-systems',
    'apa' => 'text/x-bibliography; style=apa',
    'harvard' => 'text/x-bibliography; style=harvard3',
    'ieee' => 'text/x-bibliography; style=ieee',
    'mla' => 'text/x-bibliography; style=mla',
    'vancouver' => 'text/x-bibliography; style=vancouver',
    'chicago' => 'text/x-bibliography; style=chicago-fullnote-bibliography'
  }

  # Set facet fields
  set :facet_fields, ['type', 'year', 'oa_status', 'publication', 'category']

  # Google analytics event tracking
  set :ga, Gabba::Gabba.new(ENV['GABBA_COOKIE'], ENV['GABBA_URL']) if ENV['GABBA_COOKIE']

  # Orcid endpoint
  logger.info "Configuring ORCID, client app ID #{ENV['ORCID_CLIENT_ID']} connecting to #{ENV['ORCID_URL']}"
  set :orcid_service, Faraday.new(:url => ENV['ORCID_URL'])

  # Orcid oauth2 object we can use to make API calls
  set :orcid_oauth, OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                       ENV['ORCID_CLIENT_SECRET'],
                                       site: ENV['ORCID_URL'])

  # Set up session and auth middlewares for ORCiD sign in
  use Rack::Session::Mongo, settings.mongo[ENV['DB_NAME']]
  use Rack::Flash
  use OmniAuth::Builder do
    provider :orcid, ENV['ORCID_CLIENT_ID'], ENV['ORCID_CLIENT_SECRET'],
    authorize_params: {
      scope: '/orcid-profile/read-limited /orcid-works/create'
    },
    client_options: {
      site: ENV['ORCID_URL'],
      authorize_url: "#{ENV['ORCID_URL']}/oauth/authorize",
      token_url: "#{ENV['ORCID_URL']}/oauth/token",
    },
    provider_ignores_state: true
  end

  OmniAuth.config.logger = logger

  set :show_exceptions, true
end

before do
  logger.info "Fetching #{url}, params " + params.inspect
  #logger.debug {"request.env:\n" + request.env.ai}
end

get '/' do
  if !signed_in?
    haml :splash, :locals => {:page => {:query => ""}}
  else
    params['q'] = session[:orcid][:info][:name] if !params.has_key?('q')
    logger.debug "Initiating Solr search with query string '#{params['q']}'"
    solr_result = select search_query
    logger.debug "Got some Solr results: "

    page = {
      :bare_sort => params['sort'],
      :bare_query => params['q'],
      :query_type => query_type,
      :bare_filter => params['filter'],
      :query => query_terms,
      :facet_query => abstract_facet_query,
      :page => query_page,
      :rows => {
        :options => settings.typical_rows,
        :actual => query_rows
      },
      :items => search_results(solr_result),
      :paginate => Paginate.new(query_page, query_rows, solr_result),
      :facets => !solr_result['facet_counts'].nil? ? solr_result['facet_counts']['facet_fields']
                                                   : {}
    }

    haml :results, :locals => {:page => page}
  end
end

get '/help/api' do
  haml :api_help, :locals => {:page => {:query => ''}}
end

get '/help/search' do
  haml :search_help, :locals => {:page => {:query => ''}}
end

get '/help/status' do
  haml :status_help, :locals => {:page => {:query => '', :stats => index_stats}}
end

get '/orcid/activity' do
  if signed_in?
    haml :activity, :locals => {:page => {:query => ''}}
  else
    redirect '/'
  end
end

get '/orcid/claim' do
  status = 'oauth_timeout'

  if signed_in? && params['doi']
    doi = params['doi']
    orcid_record = settings.orcids.find_one({:orcid => sign_in_id})
    already_added = !orcid_record.nil? && orcid_record['locked_dois'].include?(doi)

    logger.info "Initiating claim for #{doi}"

    if already_added
      logger.info "DOI #{doi} is already claimed, not doing anything!"
      status = 'ok'
    else
      logger.debug "Retrieving metadata from MongoDB for #{doi}"
      doi_record = settings.dois.find_one({:doi => doi})

      if !doi_record
        status = 'no_such_doi'
      else
        logger.debug "Got some DOI metadata from MongoDB: " + doi_record.ai

        claim_ok = false
        begin
          claim_ok = OrcidClaim.perform(session_info, doi_record)
        rescue => e
          # ToDo: need more useful error messaging here, for displaying to user
          logger.error "Caught exception from claim process: #{e}: \n" + e.backtrace.join("\n")
        end

        if claim_ok
          if orcid_record
            orcid_record['updated'] = true
            orcid_record['locked_dois'] << doi
            orcid_record['locked_dois'].uniq!
            settings.orcids.save(orcid_record)
          else
            doc = {:orcid => sign_in_id, :dois => [], :locked_dois => [doi]}
            settings.orcids.insert(doc)
          end

          # The work could have been added as limited or public. If so we need
          # to tell the UI.
          OrcidUpdate.perform(session_info)
          updated_orcid_record = settings.orcids.find_one({:orcid => sign_in_id})

          if updated_orcid_record['dois'].include?(doi)
            status = 'ok_visible'
          else
            status = 'ok'
          end
        end
      end
    end
  end

  content_type 'application/json'
  {:status => status}.to_json
end

get '/orcid/unclaim' do
  if signed_in? && params['doi']
    doi = params['doi']

    logger.info "Initiating unclaim for #{doi}"
    orcid_record = settings.orcids.find_one({:orcid => sign_in_id})

    if orcid_record
      orcid_record['locked_dois'].delete(doi)
      settings.orcids.save(orcid_record)
    end
  end

  content_type 'application/json'
  {:status => 'ok'}.to_json
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
  {:status => status}.to_json
end

get '/dois' do
  settings.ga.event('API', '/dois', query_terms, nil, true) if ENV['GABBA_COOKIE']
  solr_result = select(search_query)
  items = search_results(solr_result).map do |result|
    {
      :doi => result.doi,
      :score => result.score,
      :normalizedScore => result.normal_score,
      :title => result.coins_atitle,
      :fullCitation => result.citation,
      :coins => result.coins,
      :year => result.coins_year
    }
  end

  content_type 'application/json'

  if ['true', 't', '1'].include?(params[:header])
    page = {
      :totalResults => solr_result['response']['numFound'],
      :startIndex => solr_result['response']['start'],
      :itemsPerPage => query_rows,
      :query => {
        :searchTerms => params['q'],
        :startPage => query_page
      },
      :items => items,
    }

    JSON.pretty_generate(page)
  else
    JSON.pretty_generate(items)
  end
end

post '/links' do
  page = {}

  begin
    citation_texts = JSON.parse(request.env['rack.input'].read)

    if citation_texts.count > MAX_MATCH_TEXTS
      page = {
        :results => [],
        :query_ok => false,
        :reason => "Too many citations. Maximum is #{MAX_MATCH_TEXTS}"
      }
    else
      results = citation_texts.take(MAX_MATCH_TEXTS).map do |citation_text|
        terms = scrub_query(citation_text, true)
        params = {:q => terms, :fl => 'doi,score'}
        result = settings.solr.paginate 0, 1, ENV['SOLR_SELECT'], :params => params
        match = result['response']['docs'].first

        if citation_text.split.count < MIN_MATCH_TERMS
          {
            :text => citation_text,
            :reason => 'Too few terms',
            :match => false
          }
        elsif match['score'].to_f < MIN_MATCH_SCORE
          {
            :text => citation_text,
            :reason => 'Result score too low',
            :match => false
          }
        else
          {
            :text => citation_text,
            :match => true,
            :doi => match['doi'],
            :score => match['score'].to_f
          }
        end
      end

      page = {
        :results => results,
        :query_ok => true
      }
    end
  rescue JSON::ParseError => e
    page = {
      :results => [],
      :query_ok => false,
      :reason => 'Request contained malformed JSON'
    }
  end

  settings.ga.event('API', '/links', nil, page[:results].count, true) if ENV['GABBA_COOKIE']

  content_type 'application/json'
  JSON.pretty_generate(page)
end

get '/citation' do
  citation_format = settings.citation_formats[params[:format]]

  res = settings.data_service.get do |req|
    req.url "/#{params[:doi]}"
    req.headers['Accept'] = citation_format
  end

  settings.ga.event('Citations', '/citation', citation_format, nil, true) if ENV['GABBA_COOKIE']

  content_type citation_format
  res.body if res.success?
end

get '/auth/orcid/callback' do
  session[:orcid] = request.env['omniauth.auth']
  Resque.enqueue(OrcidUpdate, session_info)
  logger.info "Signing in via ORCID iD #{session[:orcid][:uid]}"
  update_profile
  haml :auth_callback
end

get '/auth/orcid/check' do
end

# Used to sign out a user but can also be used to mark that a user has seen the
# 'You have been signed out' message. Clears the user's session cookie.
get '/auth/signout' do
  session.clear
  redirect(params[:redirect_uri])
end

get "/auth/failure" do
  flash[:error] = "Authentication failed with message \"#{params['message']}\"."
  haml :auth_callback
end

get '/auth/:provider/deauthorized' do
  haml "#{params[:provider]} has deauthorized this app."
end

get '/heartbeat' do
  content_type 'application/json'

  params['q'] = 'fish'

  begin
    # Attempt a query with solr
    solr_result = select(search_query)

    # Attempt some queries with mongo
    result_list = search_results(solr_result)

    {:status => :ok}.to_json
  rescue StandardError => e
    {:status => :error, :type => e.class, :message => e}.to_json
  end
end

error do
  capture_exception env['sinatra.error'], env
  { message: env['sinatra.error'].message }.to_json
end
