require 'cgi'
require 'nokogiri'
require 'base64'
require 'namae'
require 'ostruct'
require_relative 'helpers'

class SearchResult
  include Sinatra::Search
  include Sinatra::Session

  attr_accessor :date, :year, :month, :day,
                :title, :publication, :authors, :volume, :issue, :first_page, :last_page,
                :type, :subtype, :doi, :score, :normal_score,
                :citations, :hashed, :related, :alternate, :version,
                :rights_uri, :subject, :description, :creative_commons,
                :contributor, :contributor_type, :contributors_with_type, :grant_info,
                :related_identifiers, :combined_related
  attr_reader :hashed, :doi, :title_escaped, :xml

  # Merge a mongo DOI record with solr highlight information.
  def initialize(solr_doc, solr_result, citations, user_state, related_identifiers)
    @doi = solr_doc.fetch('doi')
    @type = solr_doc.fetch('resourceTypeGeneral', nil)
    @subtype = solr_doc.fetch('resourceType', nil)
    @doc = solr_doc
    @score = solr_doc.fetch('score', nil).to_i
    @normal_score = (@score / solr_result.fetch('response', {}).fetch('maxScore', 1) * 100).to_i
    @citations = citations
    @hashed = solr_doc.fetch('mongo_id', nil)
    @user_claimed = user_state.fetch(:claimed, false)
    @in_user_profile = user_state.fetch(:in_profile, false)
    @highlights = solr_result.fetch('highlighting', {})
    @publication = find_value('publisher')
    @title = solr_doc.fetch('title', [""]).first.strip
    description = solr_doc.fetch('description', []).first
    @description = description.to_s.truncate_words(100).gsub(/\\n\\n/, "<br/>")
    @date = solr_doc.fetch('date', []).last
    @year = find_value('publicationYear')
    @month = solr_doc['month'] ? MONTH_SHORT_NAMES[solr_doc['month'] - 1] : (@date && @date.size > 6 ? MONTH_SHORT_NAMES[@date[5..6].to_i - 1] : nil)
    @day = solr_doc['day'] || @date && @date.size > 9 ? @date[8..9].to_i : nil
    # @volume = find_value('hl_volume')
    # @issue = find_value('hl_issue')
    # @authors = find_value('creator')
    # @first_page = find_value('hl_first_page')
    # @last_page = find_value('hl_last_page')
    @rights_uri = Array(solr_doc.fetch('rightsURI', nil))
    @related = solr_doc.fetch('relatedIdentifier', nil)
    @related_identifiers = related_identifiers
    @alternate = solr_doc.fetch('alternateIdentifier', nil)
    @version = solr_doc.fetch('version', nil)
    @contributor = Array(solr_doc.fetch('contributor', []))
    @contributor_type = Array(solr_doc.fetch('contributorType', []))
    xml = Base64.decode64(solr_doc.fetch('xml', "PGhzaD48L2hzaD4=\n")).force_encoding('UTF-8')
    @xml = Hash.from_xml(xml).fetch("resource", {})
    @authors = @xml.fetch("creators", {}).fetch("creator", [])
    @authors = [@authors] if @authors.is_a?(Hash)

    # Insert/update record in MongoDB
    # Hack Alert (possibly)
    MongoData.coll('dois').update({ doi: @doi }, { doi: @doi,
                                                   title: @title,
                                                   type: @type,
                                                   subtype: @subtype,
                                                   publication: @publication,
                                                   contributor: @authors,
                                                   published: {
                                                     year: @year,
                                                     month: @month,
                                                     day: @day } },
                                  { upsert: true })
  end

  def title_escaped
    title.gsub("'", %q(\\\')) if title.present?
  end

  def open_access?
    @doc['oa_status'] == 'Open Access'
  end

  def creative_commons
    if rights_uri.find { |uri| /licenses\/by-nc-nd\// =~ uri }
      'by-nc-nd'
    elsif rights_uri.find { |uri| /licenses\/by-nc-sa\// =~ uri }
      'by-nc-sa'
    elsif rights_uri.find { |uri| /licenses\/by-nc\// =~ uri }
      'by-nc'
    elsif rights_uri.find { |uri| /licenses\/by-sa\// =~ uri }
      'by-sa'
    elsif rights_uri.find { |uri| /licenses\/by\// =~ uri }
      'by'
    elsif rights_uri.find { |uri| /publicdomain\/zero/ =~ uri }
      'zero'
    else
      nil
    end
  end

  def contributors_with_type
    contributor_type.zip(contributor).map { |c| {c[0] => c[1] }}
  end

  def contributors_by_type(type)
    contributors_with_type.map do |hsh|
      hsh.select { |key, value| key == type }
    end
  end

  def grant_info
    contributors_by_type("Funder").map { |c| c["Funder"] }.compact.uniq
  end

  def related
    Array(@related).map do |item|
      { relation: item.split(':', 3)[0],
        id: item.split(':', 3)[1],
        text: item.split(':', 3)[2],
        source: "Datacite" }
    end.select { |item| item[:text].present? && item[:id] =~ /(DOI|URL)/ }
  end

  def combined_related
    (related + related_identifiers).group_by { |item| item[:relation] }
  end

  def alternate
    Array(@alternate).map do |item|
      { id: item.split(':', 2)[0],
        text: item.split(':', 2)[1] }
    end.select { |item| item[:id] !~ /citation/ }
  end

  def authors
    Array(@authors).map do |author|
      creator_name = author.fetch("creatorName", nil)
      names = Namae.parse(creator_name)
      name = names.first || OpenStruct.new(family: nil, given: nil, literal: creator_name)
      credit_name = name.family ? [name.given, name.family].join(" ") : name.literal

      { "family" => name.family,
        "given" => name.given,
        "credit-name" => credit_name,
        "id" => author.fetch("nameIdentifier", nil) }
    end
  end

  def authors_as_string
    authors[0..19].map do |author|
      author["id"].present? ? "<a href=\"/?q=#{author["id"]}\">#{author["credit-name"]}</a>" : author["credit-name"]
    end.join(", ")
  end

  def parse_author(name)
    # revert order if single words, separated by comma
    name = name.split(',')
    if name.all? { |i| i.split(' ').size > 1 }
      name.join(', ')
    else
      name.reverse.join(' ')
    end
  end

  def user_claimed?
    @user_claimed
  end

  def in_user_profile?
    @in_user_profile
  end

  def coins_atitle
    @title || ''
  end

  def coins_title
    @doc['hl_publication']
  end

  def coins_year
    @year
  end

  def coins_volume
    @doc['hl_volume']
  end

  def coins_issue
    @doc['hl_issue']
  end

  def coins_spage
    @doc['hl_first_page']
  end

  def coins_lpage
    @doc['hl_last_page']
  end

  def coins_authors
    if @authors
      authors_as_string
    else
      ''
    end
  end

  def coins_au_first
    @doc['first_author_given']
  end

  def coins_au_last
    @doc['first_author_surname']
  end

  def coins
    props = {
      'ctx_ver' => 'Z39.88-2004',
      'rft_id' => "info:doi/#{@doi}",
      'rfr_id' => 'info:sid/datacite.org:search',
      'rft.atitle' => coins_atitle,
      'rft.jtitle' => coins_title,
      'rft.date' => coins_year,
      'rft.volume' => coins_volume,
      'rft.issue' => coins_issue,
      'rft.spage' => coins_spage,
      'rft.epage' => coins_lpage,
      'rft.aufirst' => coins_au_first,
      'rft.aulast' => coins_au_last
    }

    case @type
    when 'journal_article'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:journal'
      props['rft.genre'] = 'article'
    when 'conference_paper'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:journal'
      props['rft.genre'] = 'proceeding'
    when 'Dataset'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:dc'
      props['rft.genre'] = 'dataset'
    when 'Collection'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:dc'
      props['rft.genre'] = 'collection'
    when 'Text'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:dc'
      props['rft.genre'] = 'text'
    when 'Software'
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:dc'
      props['rft.genre'] = 'software'
    else
      props['rft_val_fmt'] = 'info:ofi/fmt:kev:mtx:dc'
      props['rft.genre'] = 'unknown'
    end

    title_parts = []

    props.reject { |_, value| value.nil? }.each_pair do |key, value|
      title_parts << "#{key}=#{CGI.escape(value.to_s)}"
    end

    title = title_parts.join('&')
    coins_authors.split(',').each { |author| title += "&rft.au=#{CGI.escape(author.strip)}" } if coins_authors

    CGI.escapeHTML title
  end

  def coins_span
    "<span class=\"Z3988\" title=\"#{coins}\"><!-- coins --></span>"
  end

  # Mimic SIGG citation format.
  def citation
    a = []
    a << CGI.escapeHTML(coins_authors) unless coins_authors.empty?
    a << CGI.escapeHTML(coins_year.to_s) unless coins_year.nil?
    a << "'#{CGI.escapeHTML(coins_atitle)}'" unless coins_atitle.nil?
    a << "<i>#{CGI.escapeHTML(coins_title)}</i>" unless coins_title.nil?
    a << "vol. #{CGI.escapeHTML(coins_volume)}" unless coins_volume.nil?
    a << "no. #{CGI.escapeHTML(coins_issue)}" unless coins_issue.nil?

    if !coins_spage.nil? && !coins_lpage.nil?
      a << "pp. #{CGI.escapeHTML(coins_spage)}-#{CGI.escapeHTML(coins_lpage)}"
    elsif !coins_spage.nil?
      a << "p. #{CGI.escapeHTML(coins_spage)}"
    end

    a.join ', '
  end

  def has_path?(hash, path)
    path_found = true
    path.each do |node|
      if hash.key?(node) && !hash[node].nil?
        hash = hash[node]
      else
        path_found = false
        break
      end
    end
    path_found
  end

  def find_value(key)
    if has_path? @highlights, [@doi, key]
      @highlights[@doi][key].first
    else
      @doc[key]
    end
  end
end
