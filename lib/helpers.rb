require_relative 'doi'
require_relative 'session'
require_relative 'stats'
require_relative 'search'
require_relative 'paginate'

helpers do
  include Sinatra::Doi
  include Sinatra::Session
  include Sinatra::Stats
  include Sinatra::Search

  def citations(doi)
    citations = settings.citations.find('to.id' => doi)

    citations.map do |citation|
      hsh = {
        id: citation['from']['id'],
        authority: citation['from']['authority'],
        type: citation['from']['type']
      }

      if citation['from']['authority'] == 'cambia'
        patent = settings.patents.find_one(patent_key: citation['from']['id'])
        hsh[:url] = "http://lens.org/lens/patent/#{patent['pub_key']}"
        hsh[:title] = patent['title']
      end

      hsh
    end
  end

  def authors_text(contributors)
    authors = contributors.map do |c|
      "#{c['given_name']} #{c['surname']}"
    end
    authors.join ', '
  end

  def facet_text(name)
    name.gsub(/(_facet|URI)/, '_id').underscore.humanize
  end

  def rights_hash
    { 'http://creativecommons.org/publicdomain/zero/1.0/' => 'CC0 1.0',
      'http://creativecommons.org/licenses/by/4.0/' => 'CC BY 4.0',
      'http://creativecommons.org/licenses/by/3.0/' => 'CC BY 3.0',
      'http://creativecommons.org/licenses/by/3.0/us/' => 'CC BY 3.0 US',
      'http://creativecommons.org/licenses/by-nc/4.0/' => 'CC BY-NC 4.0',
      'http://creativecommons.org/licenses/by-nc/3.0/' => 'CC BY-NC 3.0',
      'http://creativecommons.org/licenses/by-nd/4.0/' => 'CC BY-ND 4.0',
      'http://creativecommons.org/licenses/by-nd/3.0/' => 'CC BY-ND 3.0',
      'http://creativecommons.org/licenses/by-sa/4.0/' => 'CC BY-SA 4.0',
      'http://creativecommons.org/licenses/by-sa/3.0/' => 'CC BY-SA 3.0' }
  end

  def force_utf8(str)
    str.gsub(/\s+\n/, "\n").strip.force_encoding('UTF-8')
  end
end
