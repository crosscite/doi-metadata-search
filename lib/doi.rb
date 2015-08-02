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
    s.gsub!(/\A[0-9]{4}\-[0-9]{4}\-[0-9]{4}\-[0-9]{3}[0-9X]\Z/, '\1')
  end

  def urn?(s)
    s.strip =~ /\A(urn|URN):[a-zA-Z0-9\.\/:_-]+\Z/
  end

  def contributor?(s)
    s.gsub!(/\A(creator|contributor|author):\s*.+\Z/, '\2')
  end

  def year?(s)
    s.gsub!(/\A(year|publicationYear):\s*([0-9]{4})\Z/, '\2')
  end

  def publisher?(s)
    s.gsub!(/\A(publisher|datacentre):\s*.+\Z/, '\2')
  end

  def type?(s)
    s.gsub!(/\A(type|resourceType|resourceTypeGeneral):\s*(.+)\Z/, '\2')
  end

  def subject?(s)
    s.gsub!(/\Asubject:\s*(.+)\Z/, '\1')
  end

  def rights?(s)
    s.gsub!(/\A(rights|license):\s*(.+)\Z/, '\2')
  end

  def to_doi(s)
    s = s.strip.sub(/\A(https?:\/\/)?dx\.doi\.org\//, '').sub(/\Adoi:/, '')
    s.sub(/\A(https?:\/\/)?doi.org\//, '')
  end

  def to_long_doi(s)
    doi = to_doi(s)
    normal_short_doi = doi.sub(/10\//, '').downcase

    short_doi_doc = settings.shorts.find(short_doi: normal_short_doi)

    if short_doi_doc.has_next?
      short_doi_doc.next['doi']
    else
      res = settings.dx_doi_org.get do |req|
        req.url "/10/#{normal_short_doi}"
        req.headers['Accept'] = JSON_TYPE
      end

      if res.success?
        doi = JSON.parse(res.body)['DOI']
        settings.shorts.insert(short_doi: normal_short_doi, doi: doi)
        doi
      end
    end
  end
end
