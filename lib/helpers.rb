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

  def force_utf8(str)
    str.gsub(/\s+\n/, "\n").strip.force_encoding('UTF-8')
  end
end
