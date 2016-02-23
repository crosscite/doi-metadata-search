require_relative 'mongo_data'
require_relative 'orcid_profile'
require_relative 'session'

class UpdateJob
  include Sidekiq::Worker

  def perform
    oauth_expired = false

    orcid_client = OrcidClient.new(current_user)
    response = orcid_client.get

    if response.status == 200
      profile = OrcidProfile.new(response.body)

      query = { orcid: current_user.orcid }
      orcid_record = MongoData.coll('orcids').find_one(query)

      if orcid_record
        orcid_record['dois'] = profile.dois
        MongoData.coll('orcids').save(orcid_record)
      else
        doc = { orcid: current_user.orcid, dois: profile.dois, locked_dois: [] }
        MongoData.coll('orcids').insert(doc)
      end
    else
      oauth_expired = true
    end

    !oauth_expired
  end
end
