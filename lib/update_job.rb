require_relative 'mongo_data'

class UpdateJob
  include Sidekiq::Worker

  def perform(session_info)
    oauth_expired = false

    orcid_client = OrcidClient.new(session_info)
    response = orcid_client.get

    if response.status == 200
      profile = Profile.new(response.body)

      query = { orcid: oauth['uid'] }
      orcid_record = MongoData.coll('orcids').find_one(query)

      if orcid_record
        orcid_record['dois'] = profile.dois
        MongoData.coll('orcids').save(orcid_record)
      else
        doc = { orcid: oauth['uid'], dois: profile.dois, locked_dois: [] }
        MongoData.coll('orcids').insert(doc)
      end
    else
      oauth_expired = true
    end

    !oauth_expired
  end
end
