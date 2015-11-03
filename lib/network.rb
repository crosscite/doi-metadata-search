require 'sinatra/base'
require 'json'
require 'nokogiri'

module Sinatra
  module Network
    def get_result(url, options = { content_type: 'json' })
      conn = faraday_conn(options[:content_type], options)
      conn.basic_auth(options[:username], options[:password]) if options[:username]
      conn.authorization :Bearer, options[:bearer] if options[:bearer]
      conn.options[:timeout] = options[:timeout] || DEFAULT_TIMEOUT
      if options[:data]
        response = conn.post url, {}, options[:headers] do |request|
          request.body = options[:data]
        end
      else
        response = conn.get url, {}, options[:headers]
      end
      # parsing by content type is not reliable, so we check the response format
      if json = as_json(response.body)
        json
      elsif xml = as_xml(response.body)
        xml
      else
        force_utf8(response.body)
      end
    rescue *NETWORKABLE_EXCEPTIONS => e
      rescue_faraday_error(url, e, options)
    end

    def faraday_conn(content_type = 'json', options = {})
      # use short version for html, xml and json
      content_types = { "html" => 'text/html; charset=UTF-8',
                        "xml" => 'application/xml',
                        "json" => 'application/json' }
      accept_header = content_types.fetch(content_type, content_type)

      # redirect limit
      limit = options[:limit] || 10

      Faraday.new do |c|
        c.headers['Accept'] = accept_header
        c.headers['User-Agent'] = "doi-metadata-search - http://#{ENV['HOSTNAME']}"
        c.use      FaradayMiddleware::FollowRedirects, limit: limit, cookie: :all
        c.request  :multipart
        c.request  :json if accept_header == 'application/json'
        c.use      Faraday::Response::RaiseError
        c.response :encoding
        c.adapter  Faraday.default_adapter
      end
    end

    def rescue_faraday_error(url, error, options={})
      if error.is_a?(Faraday::ResourceNotFound)
        { error: "resource not found", status: 404 }
      elsif error.is_a?(Faraday::TimeoutError) || error.is_a?(Faraday::ConnectionFailed) || (error.try(:response) && error.response[:status] == 408)
        { error: "execution expired", status: 408 }
      else
        raise error if ENV['RACK_ENV'] != 'production'
      end
    end

    def parse_error_response(string)
      if json = as_json(string)
        string = json
      elsif xml = as_xml(string)
        string = xml
      end
      string = string['error'] if string.is_a?(Hash) && string['error']
      string
    end

    def as_xml(string)
      if Nokogiri::XML(string).errors.empty?
        Hash.from_xml(string)
      else
        false
      end
    end

    def as_json(string)
      ::ActiveSupport::JSON.decode(string)
    rescue ::ActiveSupport::JSON.parse_error
      false
    end

    def force_utf8(string)
      string.gsub(/\s+\n/, "\n").strip.force_encoding('UTF-8')
    end
  end
end
