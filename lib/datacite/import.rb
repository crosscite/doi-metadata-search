require 'sinatra/base'
require 'json'
require_relative '../network'

class Import
  include Sinatra::Network

  attr_reader :offset, :rows, :from_date, :until_date

  def initialize(options = {})
    @offset = options[:offset].to_i
    @rows = options[:rows].presence || job_batch_size
    @from_date = options[:from_date].presence || (Time.now.to_date - 1.day).iso8601
    @until_date = options[:until_date].presence || Time.now.to_date.iso8601
  end

  def process_data(options)
    result = get_data(options)
    result = parse_data(result)
    result.length
  end

  def get_query_url(options = {})
    updated = "updated:[#{@from_date}T00:00:00Z TO #{@until_date}T23:59:59Z]"
    fq = "#{updated} AND has_metadata:true AND is_active:true"
    params = { q: "nameIdentifier:ORCID\\:*",
               start: @offset,
               rows: @rows,
               fl: "doi,nameIdentifier,updated",
               fq: fq,
               wt: "json" }
    url +  URI.encode_www_form(params)
  end

  def get_total(options={})
    query_url = get_query_url(options.merge(rows: 0))
    result = get_result(query_url, options)
    result.fetch("response", {}).fetch("numFound", 0)
  end

  def queue_jobs(options={})
    total = get_total(options)

    if total > 0
      # walk through paginated results
      total_pages = (total.to_f / job_batch_size).ceil

      (0...total_pages).each do |page|
        options[:offset] = page * job_batch_size
        ImportJob.perform_later(self, options)
      end
    end

    # return number of works queued
    total
  end

  def get_data(options={})
    query_url = get_query_url(options)
    get_result(query_url, options)
  end

  def parse_data(result, options={})
    result = { error: "No hash returned." } unless result.is_a?(Hash)
    return result if result[:error]

    items = result.fetch('response', {}).fetch('docs', nil)
    get_works(items).flatten
  end

  def get_works(items)
    Array(items).map do |item|
      doi = item.fetch("doi", nil)
      name_identifiers = item.fetch('nameIdentifier', []).select { |id| id =~ /^ORCID:.+/ }
      name_identifiers.map { |work| { orcid: work.split(':', 2).last, doi: doi }}
    end
  end

  def url
    "http://search.datacite.org/api?"
  end

  def job_batch_size
    1000
  end
end
