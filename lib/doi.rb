require 'sinatra/base'
require 'json'
require 'maremma'

module Sinatra
  module Doi
    JSON_TYPE = 'application/vnd.citationstyles.csl+json'

    def doi?(s)
      to_doi(s) =~ /\A10\.[0-9]{4,}\/.+/
    end

    #  Short DOIs are of the form 10/abcde. These must be used with
    # dx.doi.org.
    def short_doi?(s)
      to_doi(s) =~ /\A10\/[a-z0-9]+\Z/
    end

    # Very short DOIs are of the form abcde. These must be used with
    #  doi.org. We check for doi.org/ since characters only preclude
    #  search terms.
    def very_short_doi?(s)
      s.strip =~ /\A(https?:\/\/)?doi\.org\/[a-z0-9]+\Z/
    end

    def issn?(s)
      s.strip.upcase =~ /\A[0-9]{4}\-[0-9]{3}[0-9X]\Z/
    end

    def orcid?(s)
      s.strip =~ /\A[0-9]{4}\-[0-9]{4}\-[0-9]{4}\-[0-9]{3}[0-9X]\Z/
    end

    def urn?(s)
      s.strip =~ /\A(urn|URN):[a-zA-Z0-9\.\/:_-]+\Z/
    end

    def to_doi(s)
      s = s.to_s.strip.sub(/\A(https?:\/\/)?dx\.doi\.org\//, '').sub(/\Adoi:/, '')
      s.sub(/\A(https?:\/\/)?doi.org\//, '')
    end

    def to_long_doi(s)
      doi = to_doi(s)
      normal_short_doi = doi.sub(/10\//, '').downcase
      short_doi_doc = Sinatra::Application.settings.shorts.find(short_doi: normal_short_doi)

      if short_doi_doc.has_next?
        short_doi_doc.next['doi']
      else
        result = Maremma.get "http://doi.org/10/#{normal_short_doi}", content_type: JSON_TYPE

        if result.is_a?(Hash) && !result["error"]
          doi = result.fetch('DOI', nil)
          Sinatra::Application.settings.shorts.insert(short_doi: normal_short_doi, doi: doi)
          doi
        end
      end
    end
  end

  register Doi
end
