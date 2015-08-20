# Construct an XML object that can be deposited with ORCID

require 'nokogiri'
require_relative 'doi'
require_relative "#{ENV['RA']}/work_type"

class OrcidClaim
  include Sinatra::Doi
  include Sinatra::WorkType

  # required attributes DataCite:
  # Identifier, Creator, Title, Publisher, PublicationYear

  attr_reader :work, :doi, :contributors, :title, :publisher, :publication_year,
              :subtitle, :container_title, :publication_month, :publication_day,
              :type, :citation, :description, :url

  def initialize(work)
    @work = work
  end

  def doi
    to_doi(work.fetch('doi', nil))
  end

  def contributors
    Array(work.fetch('creator', nil)).map do |contributor|
      { orcid: nil,
        credit_name: contributor,
        role: nil }
    end
  end

  def title
    without_control(Array(work.fetch('title', [])).first)
  end

  def subtitle
    if @work['hl_subtitle'] && !@work['hl_subtitle'].empty?
      subtitle = @work['hl_subtitle'].first
      without_control(subtitle)
    end
  end

  def container_title
    Array(work.fetch('container-title', [])).first
  end

  def description
    Array(work.fetch('description', [])).first
  end

  def url
    "http://doi.org/#{doi}" if doi
  end

  def publisher
    work.fetch('publisher', nil)
  end

  def publication_year
    year = work.fetch('publicationYear', nil).to_i
    year > 0 ? year.to_s : year
  end

  def publication_month
    month = work.fetch('month', nil).to_i
    month > 0 ? pad_date_item(month) : nil
  end

  def publication_day
    day = work.fetch('day', nil).to_i
    day > 0 ? pad_date_item(day) : nil
  end

  def type
    orcid_work_type(work['type'], work['subtype'])
  end

  def citation
    conn = Faraday.new(url: 'http://data.datacite.org') do |c|
      c.response :encoding
      c.adapter Faraday.default_adapter
    end

    response = conn.get "/#{URI.encode(doi)}", {},
                        'Accept' => 'application/x-bibtex'

    if response.status == 200
      without_control(response.body)
    else
      nil
    end
  end

  def root_attributes
    { :'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :'xsi:schemaLocation' => 'http://www.orcid.org/ns/orcid https://raw.github.com/ORCID/ORCID-Source/master/orcid-model/src/main/resources/orcid-message-1.2.xsd',
      :'xmlns' => 'http://www.orcid.org/ns/orcid' }
  end

  def to_xml
    # return nil unless doi && creator && title && publisher && publication_year

    Nokogiri::XML::Builder.new do |xml|
      xml.send(:'orcid-message', root_attributes) do
        xml.send(:'message-version', ORCID_VERSION)
        xml.send(:'orcid-profile') do
          xml.send(:'orcid-activities') do
            xml.send(:'orcid-works') do
              xml.send(:'orcid-work') do
                insert_work(xml)
              end
            end
          end
        end
      end
    end.to_xml
  end

  def insert_work(xml)
    insert_titles(xml)
    insert_description(xml)
    insert_citation(xml)
    insert_type(xml)
    insert_pub_date(xml)
    insert_ids(xml)
    insert_contributors(xml)
  end

  def insert_titles(xml)
    if title || subtitle
      xml.send(:'work-title') do
        xml.title(title) if title
        xml.subtitle(subtitle) if subtitle
      end
    end

    xml.send(:'journal-title', container_title) if container_title
  end

  def insert_description(xml)
    xml.send(:'short-description', description)
  end

  def insert_citation(xml)
    xml.send(:'work-citation') do
      xml.send(:'work-citation-type', 'bibtex')
      xml.citation(citation)
    end
  end

  def insert_type(xml)
    xml.send(:'work-type', type)
  end

  def insert_pub_date(xml)
    if publication_year
      xml.send(:'publication-date') do
        xml.year(publication_year)
        xml.month(publication_month) if publication_month
        xml.day(publication_day) if publication_month && publication_day
      end
    end
  end

  def pad_date_item(item)
    result = nil
    if item
      begin
        item_int = item.to_s.strip.to_i
        if item_int >= 0 && item_int <= 11
          item_str = item_int.to_s
          if item_str.length < 2
            result = '0' + item_str
          elsif item_str.length == 2
            result = item_str
          end
        end
      rescue StandardError => e
        # Ignore type conversion errors
      end
    end
    result
  end

  def insert_ids(xml)
    xml.send(:'work-external-identifiers') do
      insert_id(xml, 'doi', doi)
      # Do not insert ISSNs and ISBNs as currently they are treated
      # as unique per work by ORCID
      # insert_id(xml, 'isbn', to_isbn(@work['isbn'].first)) if @work['isbn'] && !@work['isbn'].empty?
      # insert_id(xml, 'issn', to_issn(@work['issn'].first)) if @work['issn'] && !@work['issn'].empty?
    end
  end

  def insert_id(xml, type, value)
    xml.send(:'work-external-identifier') do
      xml.send(:'work-external-identifier-type', type)
      xml.send(:'work-external-identifier-id', value)
    end
  end

  def to_issn(uri)
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/issn\//, '')
  end

  def to_isbn(uri)
    uri.strip.sub(/\Ahttp:\/\/id.crossref.org\/isbn\//, '')
  end

  def insert_contributors(xml)
    xml.send(:'work-contributors') do
      contributors.each do |contributor|
        xml.contributor do
          insert_contributor(xml, contributor)
        end
      end
    end
  end

  def insert_contributor(xml, contributor)
    xml.send(:'contributor-orcid', contributor[:orcid]) if contributor[:orcid]
    xml.send(:'credit-name', contributor[:credit_name])
    if contributor[:role]
      xml.send(:'contributor-attributes') do
        xml.send(:'contributor-role', contributor[:role])
      end
    end
  end

  def without_control(s)
    r = ''
    s.each_codepoint do |c|
      if c >= 32
        r << c
      end
    end
    r
  end
end
