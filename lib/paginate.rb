require 'will_paginate'

class Paginate
  def initialize(page, per_page, solr_response)
    @page = page
    @per_page = per_page
    @response = solr_response['response']
    @header = solr_response['header']
  end

  def docs
    @response['docs']
  end

  attr_reader :per_page

  def current_page
    @page
  end

  def total_pages
    (@response['numFound'] / per_page.to_f).ceil
  end

  def total_rows
    @response['numFound']
  end
end
