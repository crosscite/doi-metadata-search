require_relative 'doi'
require_relative 'session_helper'
require 'sanitize'
require "json"


module Sinatra
  module Helpers
    include Sinatra::Doi
    include Sinatra::SessionHelper

    INVERSE_RELATION_TYPES = {
      "Cites" => "IsCitedBy",
      "Compiles" => "IsCompiledBy",
      "Continues" => "IsContinueddBy",
      "Corrects" => "IsCorrectedBy",
      "Documents" => "IsDocumentedBy",
      "HasMetadata" => "IsMetadataFor",
      "HasPart" => "IsPartOf",
      "IsCitedBy" => "Cites",
      "IsCompiledBy" => "Compiles",
      "IsContinuedBy" => "Continues",
      "IsCorrectedBy" => "Corrects",
      "IsDerivedFrom" => "IsSourceOf",
      "IsDocumenteddBy" => "Documents",
      "IsIdenticalTo" => "IsIdenticalTo",
      "IsMetadataFor" => "HasMetadata",
      "IsNewVersionOf" => "IsPreviousVersionOf",
      "IsOriginalFormOf" => "IsVariantFormOf",
      "IsPartOf" => "HasPart",
      "IsPreviousVersionOf" => "IsNewVersionOf",
      "IsRecommendedBy" => "Recommends",
      "IsReferencedBy" => "References",
      "IsReviewedBy" => "Reviews",
      "IsSourceOf" => "IsDerivedFrom",
      "IsSupplementTo" => "IsSupplementedBy",
      "IsSupplementedBy" => "IsSupplementTo",
      "IsVariantFormOf" => "IsOriginalFromOf",
      "Recommends" => "isRecommendedBy",
      "References" => "isReferencedBy",
      "Reviews" => "isReviewedBy",
    }

    def author_format(author)
      authors = Array(author).map do |a|
        name = a.fetch("literal", nil).presence || a.fetch("given", nil).to_s + " " + a.fetch("family", nil).to_s
        a["orcid"].present? ? "<a href=\"/people/#{orcid_from_url(a["orcid"])}\">#{name}</a>" : name
      end

      case authors.length
      when 0..2 then authors.join(" & ")
      when 3..25 then authors[0..-2].join(", ").to_s + " & " + authors.last.to_s
      else authors[0..24].join(", ").to_s + " … & " + authors.last.to_s
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

    def creative_work_type(attributes)
      type = attributes.fetch("resource-type-id", nil) || attributes.fetch("work-type-id", nil)

      case type
      when "dataset" then "Dataset"
      when "text" then "Article"
      when "software" then "SoftwareApplication"
      when "collection" then "Collection"
      when "image" then "ImageObject"
      else "CreativeWork"
      end
    end

    def resource_type_title(resource_types, id)
      resource_type = Array(resource_types).find { |p| p["id"] == id }
      return id unless resource_type.present?

      resource_type.fetch("attributes", {}).fetch("title", "")
    end

    def source_title(sources, id)
      source = Array(sources).find { |s| s["id"] == id }
      return id unless source.present?

      source.fetch("attributes", {}).fetch("title", "")
    end

    def relation_type_title(related_identifiers, id)
      related_identifier = Array(related_identifiers).find { |r| r["related-identifier"] == id } || {}
      id = related_identifier.fetch("relation-type-id", nil)
      INVERSE_RELATION_TYPES.fetch(id, "").underscore.humanize
    end

    def work_type_title(work_types, id)
      work_type = Array(work_types).find { |s| s["id"] == id }
      return id unless work_type.present?

      work_type.fetch("attributes", {}).fetch("title", "")
    end

    def metadata_format(attributes, options={})
      if attributes.fetch("work-type", nil).present?
        work_types = Array(options[:work_types])
        type = work_type_title(work_types, attributes.fetch("work-type"))
        type = type.underscore.humanize
      else
        type = attributes.fetch("resource-type-subtype", nil).presence ||
               attributes.fetch("resource-type", nil).presence || "Work"
      end

      published = format_date(attributes)
      container_title = attributes.fetch("container-title", nil)
      container_title = " via " + container_title if container_title.present?

      [type, "published", published, container_title].join(" ")
    end

    def description_format(description)
      sanitize(description.to_s.strip).truncate_words(75)
    end

    def pagination_helper(items, page, total)
      WillPaginate::Collection.create(page, DEFAULT_ROWS, [total, 1000].min) do |pager|
        pager.replace items
      end
    end

    def reduce_aggs meta, options={}
      meta = ::JSON.parse(meta) if meta.respond_to?("downcase")
      relation_types = meta.fetch("relation-types",[])
      metrics = {}
      relation_types.each do |type|
        qty = type["year-months"].map { |period| period.dig("sum")}.sum
        metrics[type.dig("id")] = qty
      end
      metrics
    end

    def license_img(license)
      uri = URI.parse(license)

      if uri.host == "creativecommons.org"
        labels = uri.path.split('/')[2].to_s.split('-')
        labels.unshift("cc")

        labels.reduce([]) do |sum, key|
          key = "zero" if %w(public publicdomain).include?(key)

          if %w(cc by nd nc sa zero).include?(key)
            sum << '<i class="cc cc-' + key + '"> </i>'
          end
          sum
        end.join(' ')
      elsif uri.host == "opensource.org"
        type = uri.path.split('/', 3).last.to_s.gsub('-', ' ')

        "<img src=\"https://img.shields.io/:license-#{URI.escape(type)}-blue.svg\" />"
      end
    end

    def credit_name(attributes)
      [attributes["given"], attributes["family"]].join(" ").presence ||
      attributes["literal"].presence ||
      attributes["github"].presence ||
      attributes["orcid"]
    end

    def contributor_as_json_ld(id:, attributes:)
      { "@context" => "http://schema.org",
        "@type" => attributes.fetch("family", nil).present? ? "Person" : "Organization",
        "@id" => id,
        "givenName" => attributes.fetch("given", nil),
        "familyName" => attributes.fetch("family", nil),
        "name" => attributes.fetch("literal", nil) }.compact.to_json
    end

    def meta_tag(name:, content:, label: "name")
      if content.is_a?(Array)
        content.map { |val| "<meta #{label}=\"#{name}\" content=\"#{val}\" />" }.join("\n")
      elsif content.present?
        "<meta #{label}=\"#{name}\" content=\"#{content}\" />"
      end
    end

    def work_as_meta_tag(id:, attributes:)
      author = attributes.fetch("author", []).map do |a|
        if a.fetch("literal", nil).present?
          a.fetch("literal")
        else
          [a.fetch("given", nil), a.fetch("family", nil)].compact.join(" ")
        end
      end

      title = escape_quotes(attributes.fetch("title", nil))
      description = escape_quotes(attributes.fetch("description", nil))

      meta = []
      meta << meta_tag(name: "DC.identifier", content: id)
      meta << meta_tag(name: "DC.type", content: attributes.fetch("resource-type-id", nil) || "work")
      meta << meta_tag(name: "DC.title", content: title)
      meta << meta_tag(name: "DC.creator", content: author)
      meta << meta_tag(name: "DC.publisher", content: escape_quotes(attributes.fetch("publisher", nil)))
      meta << meta_tag(name: "DC.date", content: escape_quotes(attributes.fetch("published", nil)))
      meta << meta_tag(name: "DC.description", content: description)
      meta << meta_tag(name: "DCTERMS.license", content: escape_quotes(attributes.fetch("license", nil)))

      meta << meta_tag(name: "og:site_name", content: title, label: "property")
      meta << meta_tag(name: "og:description", content: description, label: "property")

      meta.compact.join("\n")
    end

    def escape_quotes(str)
      return str if str.nil?

      str.gsub(/"/, '&quot;')
    end

    def works_query(options)
      params = { "id" => options.fetch("id", nil),
                 "query" => options.fetch("query", nil),
                 "resource-type-id" => options.fetch("resource-type-id", nil),
                 "relation-type-id" => options.fetch("relation-type-id", nil),
                 "data-center-id" => options.fetch("data-center-id", nil),
                 "source-id" => options.fetch("source-id", nil),
                 "person-id" => options.fetch("person-id", nil),
                 "year" => options.fetch("year", nil),
                 "registered" => options.fetch("registered", nil),
                 "sort" => options.fetch("sort", nil) }.compact

      if options[:model] == "data-centers"
        "/data-centers/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "members"
        "/members/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "sources"
        "/sources/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif options[:model] == "people"
        "/people/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      elsif params["id"].present?
        "/works/#{params['id']}?" + URI.encode_www_form(params.except('id'))
      else
        "/works?" + URI.encode_www_form(params)
      end
    end

    def data_centers_query(options)
      params = { "id" => options.fetch("id", nil),
                 "query" => options.fetch("query", nil),
                 "member-id" => options.fetch("member-id", nil),
                 "year" => options.fetch("year", nil),
                 "registration-agency-id" => options.fetch("registration-agency-id", nil) }.compact

      "/data-centers?" + URI.encode_www_form(params)
    end

    def contributions_query(options)
      params = { "id" => options.fetch("id", nil),
                 "query" => options.fetch("query", nil),
                 "resource-type-id" => options.fetch("resource-type-id", nil),
                 "relation-type-id" => options.fetch("relation-type-id", nil),
                 "data-center-id" => options.fetch("data-center-id", nil),
                 "source-id" => options.fetch("source-id", nil),
                 "year" => options.fetch("year", nil),
                 "sort" => options.fetch("sort", nil) }.compact

      if options[:model] == "data-centers"
         "/contributions?data-center-id=#{params['id']}&" + URI.encode_www_form(params.except('id'))
        elsif options[:model] == "sources"
         "/contributions?source-id=#{params['id']}&" + URI.encode_www_form(params.except('id'))
        else
        "/works?" + URI.encode_www_form(params)
      end
    end

    def works_action(item, params)
      return item["id"] if params[:external_link].present?

      if item.fetch("type", nil) == "contributions"
        id = item.fetch('attributes', {}).fetch("obj-id", nil)
      elsif item.fetch("type", nil) == "relations"
        id = item.fetch('attributes', {}).fetch("subj-id", nil)
      else
        id = item.fetch('attributes', {}).fetch("doi", nil).presence || item["id"]
      end
      id = id.gsub("https://doi.org/","")
      "/works/#{id}"
    end

    def people_action(item, params)
      if params[:external_link].present?
        item.dig("attributes", "orcid")
      else
        "/people/#{item["id"]}"
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
      Array(/\A(http|https):\/\/orcid\.org\/(.+)/.match(url)).last
    end

    def validate_orcid(orcid)
      Array(/\A(?:(http|https):\/\/orcid\.org\/)?(\d{4}-\d{4}-\d{4}-\d{3}[0-9X]+)\z/.match(orcid)).last
    end

    def validate_doi(doi)
      Array(/\A(?:(http|https):\/\/doi\.org\/)?(10\.\d{4,5}\/.+)\z/.match(doi)).last
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
      if id.starts_with?("https://doi.org")
        "?query=#{id[15..-1]}"
      else
        id
      end
    end

    def auto_update_text
      if !user_signed_in?
        'panel-default'
      else
        'panel-success'
      end
    end

    def enabled_text
      if !user_signed_in?
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

    def pluralize(n, singular, plural=nil)
      if n.to_s == "1"
          "1 #{singular}"
      elsif plural
          "#{n} #{plural}"
      else
          "#{n} #{singular}s"
      end
    end

    def format_date(attributes)
      published = attributes.fetch("published", nil)
      return "" unless published.present?

      date = get_datetime_from_iso8601(published)
      return "" unless date.present?
      
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
