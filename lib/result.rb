# -*- coding: utf-8 -*-
require 'cgi'

class SearchResult

  attr_accessor :year, :month, :day
  attr_accessor :title, :publication, :authors, :volume, :issue
  attr_accessor :first_page, :last_page
  attr_accessor :type, :doi, :score, :normal_score

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

  # Merge a mongo DOI record with solr highlight information.
  def initialize mongo_record, solr_doc, solr_result
    @doi = mongo_record['doi']
    @type = mongo_record['type']
    @doc = solr_doc
    @record = mongo_record
    @score = solr_doc['score']
    @normal_score = ((@score / solr_result['response']['maxScore']) * 100).to_i

    highlights = solr_result['highlighting']

    # Publication title
    if has_path? highlights, [@doi, 'hl_publication']
      @publication = highlights[@doi]['hl_publication'].first
    elsif  has_path? mongo_record, ['journal', 'full_title']
      @publication = mongo_record['journal']['full_title']
    elsif has_path? mongo_record, ['proceedings', 'title']
      @publication = mongo_record['proceedings']['title']
    end

    # Work title
    if has_path? highlights, [@doi, 'hl_title']
      @title = highlights[@doi]['hl_title'].first
    elsif has_path? mongo_record, ['title']
      @title = mongo_record['title']
    end

    # Year
    if has_path? highlights, [@doi, 'hl_year']
      @year = highlights[@doi]['hl_year'].first
    elsif has_path? mongo_record, ['published', 'year']
      @year = mongo_record['published']['year'].to_i
    end

    # Month
    if has_path? mongo_record, ['published', 'month']
      month_index = mongo_record['published']['month'].to_i - 1
      @month = ENGLISH_MONTHS[month_index]
    end

    # Day
    if has_path? mongo_record, ['published', 'day']
      @day = mongo_record['published']['day']
    end

    # Volume
    if has_path? highlights, [@doi, 'hl_volume']
      @volume = highlights[@doi]['hl_volume'].first
    elsif has_path? mongo_record, ['volume']
      @volume = mongo_record['volume']
    end

    # Issue
    if has_path? highlights, [@doi, 'hl_issue']
      @issue = highlights[@doi]['hl_issue'].first
    elsif has_path? mongo_record, ['issue']
      @issue = mongo_record['issue']
    end

    # Authors
    if has_path? highlights, [@doi, 'hl_authors']
      @authors = highlights[@doi]['hl_authors'].first
    elsif has_path? mongo_record, ['contributors']
      authors = mongo_record['contributors'].map do |c|
        "#{c['given_name']} #{c['surname']}"
      end
      @authors = authors.join ', '
    end

    # Pages
    if has_path? mongo_record, ['pages', 'first_page']
      @first_page = mongo_record['pages']['first_page']
    end

    if has_path? mongo_record, ['pages', 'last_page']
      @last_page = mongo_record['pages']['last_page']
    end
  end

  def open_access?
    @doc['oa_status'] == 'Open Access'
  end

  def coins_atitle
    @record['title'] if has_path? @record, ['title']
  end

  def coins_title
    if has_path? @record, ['journal', 'full_title']
      @record['journal']['full_title']
    elsif has_path? @record, ['proceedings', 'title']
      @record['proceedings']['title']
    end
  end

  def coins_year
    @record['published']['year'].to_i if has_path? @record, ['published', 'year']
  end

  def coins_volume
    @record['volume'] if has_path? @record, ['volume']
  end

  def coins_issue
    @record['issue'] if has_path? @record, ['issue']
  end

  def coins_spage
    @record['pages']['first_page'] if has_path? @record, ['pages', 'first_page']
  end

  def coins_lpage
    @record['pages']['last_page'] if has_path? @record, ['pages', 'last_page']
  end

  def coins_authors
    if @record.has_key? 'contributors'
      @record['contributors'].map do |author|
        "#{author['given_name']} #{author['surname']}"
      end
    else
      []
    end
  end

  def coins_au_first
    unless @record['contributors'].nil? || @record['contributors'].empty?
      @record['contributors'].first['given_name']
    end
  end

  def coins_au_last
    unless @record['contributors'].nil? || @record['contributors'].empty?
      @record['contributors'].first['surname']
    end
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
      'rft.lpage' => coins_lpage,
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
    
    coins_authors.drop(1).each { |author| title += "&rft.au=#{CGI.escape(author)}" }

    CGI.escapeHTML title
  end

  def coins_span
    "<span class=\"Z3988\" title=\"#{coins}\"><!-- coins --></span>"
  end

  # Mimic SIGG citation format.
  def citation
    a = []
    a << CGI.escapeHTML(coins_authors.join(', ')) unless coins_authors.empty?
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

    

    
