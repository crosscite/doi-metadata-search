require_relative 'doi'
require_relative 'session'
require_relative "#{ENV['RA']}/stats"
require_relative 'search'
require_relative 'paginate'
require 'sanitize'

helpers do
  include Sinatra::Doi
  include Sinatra::Session
  include Sinatra::Stats
  include Sinatra::Search

  def citations(doi)
    citations = Sinatra::Application.settings.citations.find('to.id' => doi)

    citations.map do |citation|
      hsh = {
        id: citation['from']['id'],
        authority: citation['from']['authority'],
        type: citation['from']['type']
      }

      if citation['from']['authority'] == 'cambia'
        patent = Sinatra::Application.settings.patents.find_one(patent_key: citation['from']['id'])
        hsh[:url] = "http://lens.org/lens/patent/#{patent['pub_key']}"
        hsh[:title] = patent['title']
      end

      hsh
    end
  end

  def author_format(author)
    authors = Array(author).map do |a|
      name = a.fetch("given", nil).to_s + " " + a.fetch("family", nil).to_s
      a["id"].present? ? "<a href=\"/?q=#{a["id"]}\">#{name}</a>" : name
    end

    case authors.length
    when 0, 1, 2 then authors.join(" & ")
    when 3, 4, 5, 6, 7 then authors[0..-2].join(", ") + " & " + authors.last
    else authors[0..5].join(", ") + " … & " + authors.last
    end
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
