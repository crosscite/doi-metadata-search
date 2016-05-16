require_relative 'doi'
require_relative 'session_helper'
require_relative 'search'
require 'sanitize'

helpers do
  include Sinatra::Doi
  include Sinatra::SessionHelper
  include Sinatra::Search

  def author_format(author)
    authors = Array(author).map do |a|
      name = a.fetch("given", nil).to_s + " " + a.fetch("family", nil).to_s
      a["orcid"].present? ? "<a href=\"/works?q=#{orcid_from_url(a["orcid"])}\">#{name}</a>" : name
    end

    case authors.length
    when 0, 1, 2 then authors.join(" & ")
    when 3, 4, 5, 6, 7 then authors[0..-2].join(", ") + " & " + authors.last
    else authors[0..5].join(", ") + " … & " + authors.last
    end
  end

  def prefix_format(attributes)
    prefixes = attributes.fetch("prefixes", [])
    case prefixes.length
    when 0 then ""
    when 1 then "Prefix: " + prefixes.first
    else "Prefixes: " + prefixes.join(" ")
    end
  end

  def resource_type_title(resource_types, id)
    resource_type = resource_types.find { |p| p["id"] == id }
    return "" unless resource_type.present?

    resource_type.fetch("attributes", {}).fetch("title", "")
  end

  def publisher_title(publishers, id)
    publisher = publishers.find { |p| p["id"] == id }
    return "" unless publisher.present?

    publisher.fetch("attributes", {}).fetch("title", "")
  end

  def registration_agency_format(attributes)
    ra = attributes.fetch("registration-agency-id", nil)
    registration_agencies = { "crossref" => "Crossref",
                              "datacite" => "DataCite" }
    registration_agencies.fetch(ra, "")
  end

  def region_format(attributes)
    region = attributes.fetch("region", nil)
    regions = { "amer" => "Americas",
                "apac" => "Asia Pacific",
                "emea" => "EMEA" }
    regions.fetch(region, "")
  end

  def metadata_format(attributes)
    type = attributes.fetch("resource-type", nil).presence ||
           attributes.fetch("resource-type-general", nil).presence || "Work"
    type = type.underscore.humanize
    published = attributes.fetch("published", "0000")
    container_title = attributes.fetch("container-title", nil)
    container_title = " via " + "<a href=\"/works?publisher-id=#{attributes.fetch("publisher-id", "")}\">#{container_title}</a>" if container_title.present?

    [type, "published", published, container_title].join(" ")
  end

  def description_format(description)
    description.to_s.truncate_words(75).gsub(/\\n\\n/, "<br/>")
  end

  def credit_name(attributes)
    [attributes["given"], attributes["family"]].join(" ")
  end

  def works_query(params)
    "/works?" + URI.encode_www_form(params)
  end

  def number_with_delimiter(number)
    begin
      Float(number)
    rescue ArgumentError, TypeError
      return number
    end

    options = {delimiter: ',', separator: '.'}
    parts = number.to_s.to_str.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    parts.join(options[:separator])
  end

  def orcid_from_url(url)
    Array(/\Ahttp:\/\/orcid\.org\/(.+)/.match(url)).last
  end

  def related_link(id)
    if id.starts_with?("http://doi.org")
      "?q=#{id[15..-1]}"
    else
      id
    end
  end

  def auto_update_text
    if !signed_in?
      'panel-default'
    else
      'panel-success'
    end
  end

  def enabled_text
    if !signed_in?
      ''
    else
      '<span class="small pull-right">enabled</span>'
    end
  end

  def container_text(container_title)
    container_title.present? ? " in " + container_title + ". " : ". "
  end

  def facet_text(name)
    if name == "datacentre_facet"
      "Data center"
    else
      name.gsub(/(_facet|URI)/, '_id').underscore.humanize
    end
  end

  def center_text(name)
    start = name.index("- ") + 2
    name[start..-1]
  end

  def issued_text(issued)
    date_parts = issued["date-parts"].first
    date = Date.new(*date_parts)

    case date_parts.length
    when 1 then date.strftime("%Y")
    when 2 then date.strftime("%B %Y")
    when 3 then date.strftime("%B %-d, %Y")
    end
  end

  def uncamelize(string)
    string.split(/(?=[A-Z])/).join(' ').capitalize
  end

  def sanitize(string)
    Sanitize.fragment(string, :elements => ['br'])
  end

  def rights_hash
    { 'http://creativecommons.org/publicdomain/zero/1.0/' => 'CC0 1.0',
      'http://creativecommons.org/publicdomain/zero/1.0/legalcode' => 'CC0 1.0',
      'http://creativecommons.org/licenses/by/4.0/' => 'CC BY 4.0',
      'http://creativecommons.org/licenses/by/4.0' => 'CC BY 4.0',
      'http://creativecommons.org/licenses/by/3.0/' => 'CC BY 3.0',
      'http://creativecommons.org/licenses/by/3.0/us/' => 'CC BY 3.0 US',
      'http://creativecommons.org/licenses/by-nc/4.0/' => 'CC BY-NC 4.0',
      'http://creativecommons.org/licenses/by-nc/4.0' => 'CC BY-NC 4.0',
      'http://creativecommons.org/licenses/by-nc/3.0/' => 'CC BY-NC 3.0',
      'http://creativecommons.org/licenses/by-nd/4.0/' => 'CC BY-ND 4.0',
      'http://creativecommons.org/licenses/by-nd/3.0/' => 'CC BY-ND 3.0',
      'http://creativecommons.org/licenses/by-nd/3.0/de/legalcode' => 'CC BY-ND 3.0 DE',
      'http://creativecommons.org/licenses/by-sa/4.0/' => 'CC BY-SA 4.0',
      'http://creativecommons.org/licenses/by-sa/3.0/' => 'CC BY-SA 3.0',
      'http://creativecommons.org/licenses/by-nc-nd/4.0/' => 'CC BY-NC-ND 4.0',
      'http://creativecommons.org/licenses/by-nc-sa/4.0/legalcode' => 'CC BY-NC-SA 4.0',
      'http://creativecommons.org/licenses/by-nc-sa/3.0/' => 'CC BY-NC-SA 3.0',
      'http://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' => 'CC BY-NC-SA 3.0',
      'http://creativecommons.org/licenses/by-nc-sa/3.0/de/' => 'CC BY-NC-SA 3.0 DE' }
  end

  def formats_hash
    { 'applicationpdf' => 'PDF',
      'applicationjson' => 'JSON',
      'applicationzip' => 'ZIP',
      'applicationxml' => 'XML',
      'applicationmsword' => 'MS Word',
      'applicationmsexcel' => 'MS Excel',
      'applicationxcmdixml' => 'CMDI XML',
      'applicationxspsssav' => 'SPSS SAV',
      'applicationxstata' => 'Stata',
      'applicationxr' => 'R' }
  end
end
