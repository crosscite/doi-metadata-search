class OrcidProfile
  attr_reader :response, :version, :uid, :dois

  def initialize(response)
    @response = JSON.parse(response)
  end

  def version
    response.fetch('message-version', nil)
  end

  def uid
    response.fetch('orcid-profile', {}).fetch('orcid-identifier', {}).fetch('path', nil)
  end

  def dois
    if !has_path?(response, ['orcid-profile', 'orcid-activities'])
      []
    else
      works = response['orcid-profile']['orcid-activities']['orcid-works']['orcid-work']

      extracted_dois = works.map do |work_loc|
        doi = nil
        if has_path?(work_loc, ['work-external-identifiers', 'work-external-identifier'])
          ids_loc = work_loc['work-external-identifiers']['work-external-identifier']

          ids_loc.each do |id_loc|
            id_type = id_loc['work-external-identifier-type']
            id_val = id_loc['work-external-identifier-id']['value']

            if id_type.upcase == 'DOI'
              doi = id_val
            end
          end

        end
        doi
      end

      extracted_dois.compact
    end
  end

  def has_path?(hsh, path)
    loc = hsh
    path.each do |path_item|
      if loc[path_item]
        loc = loc[path_item]
      else
        loc = nil
        break
      end
    end
    loc != nil
  end
end
