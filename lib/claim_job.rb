require_relative 'mongo_data'
require_relative 'session'
require_relative 'doi'

class ClaimJob
  include Sidekiq::Worker

  def perform(work)
    oauth_expired = false

    orcid_claim = OrcidClaim.new(work)

    # send error message to bugsnag with problematic xml
    Bugsnag.before_notify_callbacks << lambda {|notif|
      notif.add_tab(:orcid_claim, {
        orcid_claim: orcid_claim.to_xml
      })
    }

    orcid_client = OrcidClient.new
    response = orcid_client.post(orcid_claim.to_xml)
    oauth_expired = response.status >= 400

    !oauth_expired
  end
end
