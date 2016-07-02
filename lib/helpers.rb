require_relative 'doi'
require_relative 'session_helper'
require 'sanitize'

module Sinatra
  module Helpers
    include Sinatra::Doi
    include Sinatra::SessionHelper

    def author_format(author)
      authors = Array(author).map do |a|
        name = a.fetch("given", nil).to_s + " " + a.fetch("family", nil).to_s
        a["orcid"].present? ? "<a href=\"/contributors/#{orcid_from_url(a["orcid"])}\">#{name}</a>" : name
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

    def itemtype_format(attributes)
      type = attributes.fetch("resource-type-general", nil) || attributes.fetch("type", nil)

      case type
      when "dataset" then "http://schema.org/Dataset"
      else "http://schema.org/CreativeWork"
      end
    end

    def resource_type_title(resource_types, id)
      resource_type = Array(resource_types).find { |p| p["id"] == id }
      return id unless resource_type.present?

      resource_type.fetch("attributes", {}).fetch("title", "")
    end

    def publisher_title(publishers, id)
      publisher = Array(publishers).find { |p| p["id"] == id }
      return id unless publisher.present?

      publisher.fetch("attributes", {}).fetch("title", "")
    end

    def member_title(members, id)
      member = Array(members).find { |m| m["id"] == id }
      return id unless member.present?

      member.fetch("attributes", {}).fetch("title", "")
    end

    def source_title(sources, id)
      source = Array(sources).find { |s| s["id"] == id }
      return id unless source.present?

      source.fetch("attributes", {}).fetch("title", "")
    end

    def group_title(groups, id)
      group = Array(groups).find { |s| s["id"] == id }
      return id unless group.present?

      group.fetch("attributes", {}).fetch("title", "")
    end

    def relation_type_title(relation_types, id)
      relation_type = Array(relation_types).find { |s| s["id"] == id }
      return id unless relation_type.present?

      relation_type.fetch("attributes", {}).fetch("title", "")
    end

    def work_type_title(work_types, id)
      work_type = Array(work_types).find { |s| s["id"] == id }
      return id unless work_type.present?

      work_type.fetch("attributes", {}).fetch("title", "")
    end

    def registration_agency_format(attributes)
      ra = attributes.fetch("registration-agency-id", nil)
      registration_agencies = { "crossref" => "Crossref",
                                "datacite" => "DataCite",
                                "github" => "GitHub" }
      registration_agencies.fetch(ra, "")
    end

    def region_format(attributes)
      region = attributes.fetch("region", nil)
      regions = { "amer" => "Americas",
                  "apac" => "Asia Pacific",
                  "emea" => "EMEA" }
      regions.fetch(region, "")
    end

    def metadata_format(attributes, options={})
      if attributes.fetch("type", nil).present?
        work_types = Array(options[:work_types])
        type = work_type_title(work_types, attributes.fetch("type"))
        type = type.underscore.humanize
      else
        type = attributes.fetch("resource-type", nil).presence ||
               attributes.fetch("resource-type-general", nil).presence || "Work"
        type = type.underscore.humanize
      end

      published = format_date(attributes)
      container_title = attributes.fetch("container-title", nil)
      container_title = " via " + container_title if container_title.present?

      [type, "published", published, container_title].join(" ")
    end

    def description_format(description)
      sanitize(description.to_s.strip).truncate_words(75)
    end

    def license_img(license)
      uri = URI.parse(license)
      if uri.host == "creativecommons.org"
        _head, prefix, type, version, _tail = uri.path.split('/', 5)
        if prefix == "publicdomain"
          "https://licensebuttons.net/p/zero/1.0/80x15.png"
        else
          version = version.to_s.gsub(/(\d)\.\d/, '/1.0')
          "https://licensebuttons.net/l/#{type}/#{version}/80x15.png"
        end
      elsif uri.host == "opensource.org"
        _head, prefix, type = uri.path.split('/', 3)
        type = type.gsub('-', ' ')
        "https://img.shields.io/:license-#{URI.escape(type)}-blue.svg"
      end
    end

    def credit_name(attributes)
      [attributes["given"], attributes["family"]].join(" ").presence ||
      attributes["literal"].presence ||
      attributes["github"].presence ||
      attributes["orcid"]
    end

    def contributor_id(attributes)
      attributes.fetch("orcid", nil).presence || attributes.fetch("github", nil)
    end

    def works_query(options)
      params = { "id" => options.fetch("id", nil),
                 "q" => options.fetch("q", nil),
                 "resource-type-id" => options.fetch("resource-type-id", nil),
                 "relation-type-id" => options.fetch("relation-type-id", nil),
                 "publisher-id" => options.fetch("publisher-id", nil),
                 "source-id" => options.fetch("source-id", nil),
                 "year" => options.fetch("year", nil),
                 "sort" => options.fetch("sort", nil) }.compact

      if options[:model] == "data-centers"
        "/data-centers/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "members"
        "/members/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "sources"
        "/sources/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "contributors"
        "/contributors/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif params["id"].present?
        "/works/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      else
        "/works?" + URI.encode_www_form(params)
      end
    end

    def works_action(item, params)
      if params[:external_link].present?
        item["id"]
      elsif item.fetch("type", nil) == "contributions"
        "/works/" + item.fetch('attributes', {}).fetch("obj-id", nil)
      elsif item.fetch("type", nil) == "relations"
        "/works/" + item.fetch('attributes', {}).fetch("subj-id", nil)
      else
        id = item.fetch('attributes', {}).fetch("doi", nil).presence || item["id"]
        "/works/#{id}"
      end
    end

    def contributors_action(item, params)
      if params[:external_link].present?
        item["id"]
      else
        "/contributors/" + contributor_id(item.fetch("attributes", {}))
      end
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

    def validate_orcid(orcid)
      Array(/\A(?:http:\/\/orcid\.org\/)?(\d{4}-\d{4}-\d{4}-\d{3}[0-9X]+)\z/.match(orcid)).last
    end

    def github_from_url(url)
      return {} unless /\Ahttps:\/\/github\.com\/(.+)(?:\/)?(.+)?(?:\/tree\/)?(.*)\z/.match(url)
      words = URI.parse(url).path[1..-1].split('/')

      { owner: words[0],
        repo: words[1],
        release: words[3] }.compact
    end

    def github_repo_from_url(url)
      github_from_url(url).fetch(:repo, nil)
    end

    def github_release_from_url(url)
      github_from_url(url).fetch(:release, nil)
    end

    def github_owner_from_url(url)
      github_from_url(url).fetch(:owner, nil)
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

    def format_date(attributes)
      published = attributes.fetch("published", nil)
      return "" unless published.present?

      date = get_datetime_from_iso8601(published)
      year, month, day = get_year_month_day(published)

      if day
        date.strftime("%B %-d, %Y")
      elsif month
        date.strftime("%B %Y")
      elsif year
        date.strftime("%Y")
      else
        ""
      end
    end

    def get_year_month(iso8601_time)
      return [] if iso8601_time.nil?

      year = iso8601_time[0..3]
      month = iso8601_time[5..6]

      [year.to_i, month.to_i].reject { |part| part == 0 }
    end

    def get_year_month_day(iso8601_time)
      return [] if iso8601_time.nil?

      year = iso8601_time[0..3]
      month = iso8601_time[5..6]
      day = iso8601_time[8..9]

      [year.to_i, month.to_i, day.to_i].reject { |part| part == 0 }
    end

    # parsing of incomplete iso8601 timestamps such as 2015-04 is broken
    # in standard library
    # return nil if invalid iso8601 timestamp
    def get_datetime_from_iso8601(iso8601_time)
      ISO8601::DateTime.new(iso8601_time).to_time.utc
    rescue
      nil
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
end

Sinatra::Application.helpers Sinatra::Helpers
