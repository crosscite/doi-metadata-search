# -*- coding: utf-8 -*-
require 'sinatra'
require 'json'
require 'rsolr'
require 'mongo'
require 'haml'
require 'will_paginate'

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
    "#{params['q'].gsub(/\(\)\-:/, '')}"
  end

  def search_query
    {
      :q => query_terms,
      :fl => query_columns,
      :rows => query_rows
    }
  end
end

get '/' do
  haml :index
end

get '/dois' do
  results = select search_query

  doi_records = results['response']['docs'].map do |doc|
    settings.dois.find_one(:doi => doc['doi'])
  end
  
  page = {
    :query => query_terms,
    :page => query_page,
    :rows => {
      :options => settings.typical_rows,
      :actual => query_rows
    },
    :items => doi_records,
    :paginate => Paginate.new(query_page, query_rows, results)
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


