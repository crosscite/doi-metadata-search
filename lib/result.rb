# -*- coding: utf-8 -*-
require 'cgi'

class SearchResult

  attr_accessor :year, :month, :day
  attr_accessor :title, :publication, :authors, :volume, :issue
  attr_accessor :first_page, :last_page
  attr_accessor :type, :doi, :score, :normal_score
  attr_accessor :citations, :hashed

  ENGLISH_MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

  def has_path? hash, path
    path_found = true
    path.each do |node|
      if hash.has_key?(node) && !hash[node].nil?
        hash = hash[node]
      else
        path_found = false
        break
      end
    end
    path_found
  end

  def find_value key
    if has_path? @highlights, [@doi, key]
      @highlights[@doi][key].first
    else
      @doc[key]
    end
  end

  # Merge a mongo DOI record with solr highlight information.
  def initialize solr_doc, solr_result, citations, claimed
    @doi = solr_doc['doi']
    @type = solr_doc['type']
    @doc = solr_doc
    @score = solr_doc['score']
    @normal_score = ((@score / solr_result['response']['maxScore']) * 100).to_i
    @citations = citations
    @hashed = solr_doc['mongo_id']
    @claimed = claimed

    @highlights = solr_result['highlighting']

    @publication = find_value('hl_publication')
    @title = find_value('hl_title')
    @year = find_value('hl_year')
    @month = ENGLISH_MONTHS[solr_doc['month'] - 1] if solr_doc['month']
    @day = solr_doc['day']
    @volume = find_value('hl_volume')
    @issue = find_value('hl_issue')
    @authors = find_value('hl_authors')
    @first_page = find_value('hl_first_page')
    @last_page = find_value('hl_last_page')
  end

  def doi
    @doi
  end

  def open_access?
    @doc['oa_status'] == 'Open Access'
  end

  def claimed?
    @claimed
  end

  def coins_atitle
    @doc['hl_title']
  end

  def coins_title
    @doc['hl_publication']
  end

  def coins_year
    @doc['hl_year']
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
    if @doc['hl_authors']
      @doc['hl_authors']
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
      'rfr_id' => 'info:sid/crossref.org:search',
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
    end

    title_parts = []

    props.reject { |_, value| value.nil? }.each_pair do |key, value|
      title_parts << "#{key}=#{CGI.escape(value.to_s)}"
    end

    title = title_parts.join('&')

    coins_authors.split(',').each { |author| title += "&rft.au=#{CGI.escape(author)}" }

    CGI.escapeHTML title
  end

  def coins_span
    "<span class=\"Z3988\" title=\"#{coins}\"><!-- coins --></span>"
  end

  # Mimic SIGG citation format.
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
end

