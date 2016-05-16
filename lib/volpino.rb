require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Volpino
    # query Profiles server, check whether list of dois has been claimed by particular user
    def get_claims(current_user, works)
      return [] unless current_user.present? && works.present? && ENV["ORCID_UPDATE_URL"].present?

      dois = found_dois(works)
      response = Maremma.get "#{ENV['ORCID_UPDATE_URL']}/api/users/#{current_user.orcid}/claims?dois=#{dois.join(",")}", token: current_user.api_key

      # flash[:error] = "Claim lookup failed with message \"#{response['errors'].map { |e| e['title']}.join(',')}\"."
      return response['errors'] if response['errors'].present?

      claimed_works = response.fetch('data', [])
      works.map do |work|
        claimed_work = claimed_works.find { |w| work['id'] == 'http://doi.org/' + w.fetch('attributes', {}).fetch('doi', '') } || {}
        work["attributes"]["claim-status"] = claimed_work.fetch('attributes', {}).fetch('state', 'none')
        work
      end
    end

    def found_dois(works)
      works.map { |w| w.fetch("attributes", {}).fetch("doi", nil) }
    end
  end
end
