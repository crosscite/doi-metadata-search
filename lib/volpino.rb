require 'sinatra/base'
require 'maremma'
require 'rack-flash'

module Sinatra
  module Volpino
    # query Profiles server, check whether list of dois has been claimed by particular user
    def get_claims(current_user, dois)
      return [] unless current_user.present? && dois.present? && ENV["JWT_HOST"].present?

      response = Maremma.get "#{ENV['JWT_HOST']}/api/users/#{current_user.orcid}/claims?dois=#{dois.join(",")}", token: current_user.api_key

      flash[:error] = "Claim lookup failed with message \"#{response['errors'].map { |e| e['title']}.join(',')}\"." if response['errors'].present?

      response.fetch('data', []).map { |claim| { 'doi' => claim.fetch('attributes', {}).fetch('doi', nil),
                                                 'status' => claim.fetch('attributes', {}).fetch('state', 'none') }}
    end
  end
end
