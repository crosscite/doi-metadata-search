require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Volpino

    # query Profiles server, check whether list of dois has been claimed by particular user
    def get_claims(current_user, dois)
      return {} unless current_user.present? && current_user.orcid.present? && dois.present?

      url = "#{ENV['ORCID_UPDATE_URL']}/claims?user-id=#{current_user.orcid}&dois=#{dois.join(",")}"
      response = Maremma.get url, bearer: current_user.jwt, timeout: 20

      { data: Array(response.body.fetch("data", [])),
        errors: Array(response.body.fetch("errors", [])),
        meta: response.body.fetch("meta", {}) }
    end

    def merge_claims(items, claims)
      items.map do |item|
        claim = Array(claims).find { |c| c.fetch('attributes', {}).fetch('doi', "claim").end_with?(item.fetch('attributes', {}).fetch('doi', "item")) } || {}
        item["attributes"]["claim-status"] = claim.fetch('attributes', {}).fetch('state', 'none')
        item
      end
    end

    def get_claimed_items(current_user, items)
      return items unless current_user.present? && items.present? && ENV["ORCID_UPDATE_URL"].present?

      dois = found_dois(items)
      claims = get_claims(current_user, dois)[:data]
      merge_claims(items, claims)
    end

    # select works registered via this registration agency, or any relation or contribution
    def found_dois(items)
      items.reduce([]) do |sum, item|
        # if item.is_a?(Hash) && item.fetch("attributes", {}).fetch("registration-agency-id", nil) == ENV['RA']
        if item.is_a?(Hash)
          sum << item.fetch("attributes", {}).fetch("doi", nil)
        else
          sum
        end
      end.compact
    end
  end

  helpers Volpino
end
