# -*- coding: utf-8 -*-
require 'sinatra'
require 'json'
require 'rsolr'
require 'mongo'
require 'haml'
require 'will_paginate'
require 'cgi'

require_relative 'lib/paginate'
require_relative 'lib/bootstrap'

configure do
  config = JSON.parse(File.open('conf/app.json').read)
  config.each_pair do |key, value|
    set key.to_sym, value
  end

  # Configure solr
  set :solr, RSolr.connect(:url => settings.solr_url)

  # Configure mongo
  set :mongo, Mongo::Connection.new(settings.mongo_host)
  set :dois, settings.mongo[settings.mongo_db]['dois']
end

helpers do
  def doi? s
    to_doi(s) =~ /10\.[0-9]{4}\/.+/
  end

  def to_doi s
    s.strip.sub(/\A(https?:\/\/)?dx\.doi\.org\//, '').sub(/\Adoi:/, '')
  end

  def partial template, locals
    haml template.to_sym, :layout => false, :locals => locals
  end 

  def select query_params
    page = query_page
    rows = query_rows
    results = settings.solr.paginate page, rows, settings.solr_select, :params => query_params
  end

  def query_page
    if params.has_key? 'page'
      params['page'].to_i
    else
      1
    end
  end

  def query_rows
    if params.has_key? 'rows'
      params['rows'].to_i
    else
      settings.default_rows
    end
  end

  def query_columns
    ['*', 'score']
  end

  def query_terms
    if doi? params['q']
      "doi:\"#{to_doi(params['q']).downcase}\""
    else
      "#{params['q'].gsub(/\(\)\-:/, '')}"
    end
  end

  def abstract_facet_query
    fq = {}
    ['type', 'year', 'publication', 'category'].each do |field|
      if params.has_key? field
        p params[field]
        params[field].split(';').each do |val|
          fq[field] ||= []
          fq[field] << val
        end
      end
    end
    fq
  end

  def facet_query
    fq = []
    abstract_facet_query.each_pair do |name, values|
      values.each do |value|
        fq << "#{name}: \"#{value}\""
      end
    end
    fq
  end

  def search_query
    fq = facet_query
    query  = {
      :q => query_terms,
      :fl => query_columns,
      :rows => query_rows,
      :facet => 'true',
      'facet.field' => ['type', 'year', 'publication', 'category'],
      :hl => 'true',
      'hl.fl' => 'hl_*',
      'hl.simple.pre' => '<span class="hl">',
      'hl.simple.post' => '</span>',
      'hl.mergeContinuous' => 'true',
      'hl.snippets' => 10,
      'hl.fragsize' => 0
    }

    query['fq'] = fq unless fq.empty?
    query
  end

  def facet_link_not field_name, field_value
    fq = abstract_facet_query
    fq[field_name].delete field_value
    fq.delete(field_name) if fq[field_name].empty?

    link = "/dois?q=#{CGI.escape(params['q'])}"
    fq.each_pair do |field, vals|
      link += "&#{field}=#{CGI.escape(vals.join(';'))}"
    end
    link
  end

  def facet_link field_name, field_value
    fq = abstract_facet_query
    fq[field_name] ||= []
    fq[field_name] << field_value

    link = "/dois?q=#{CGI.escape(params['q'])}"
    fq.each_pair do |field, vals|
      link += "&#{field}=#{CGI.escape(vals.join(';'))}"
    end
    link
  end

  def facet? field_name
    abstract_facet_query.has_key? field_name
  end
end

get '/' do
  haml :splash, :locals => {:page => {:query => ""}}
end

get '/splash' do
  haml :splash, :locals => {:page => {:query => ""}}
end

get '/dois' do
  results = select search_query

  doi_records = results['response']['docs'].map do |doc|
    settings.dois.find_one(:doi => doc['doi'])
  end

  page = {
    :query => query_terms,
    :facet_query => abstract_facet_query,
    :page => query_page,
    :rows => {
      :options => settings.typical_rows,
      :actual => query_rows
    },
    :items => doi_records,
    :paginate => Paginate.new(query_page, query_rows, results),
    :facets => results['facet_counts']['facet_fields'],
    :highlights => results['highlighting']
  }

  haml :results, :locals => {:page => page}
end

get '/doi/citation/*' do
  # return citation text for a doi
end

get '/doi/metadata/*' do
  # download a certain representation
end

get '/doi/*' do
  # show DOI as single result
end


