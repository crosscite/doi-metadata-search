require 'sinatra/base'
require 'sinatra/json'
require 'uri'

module Sinatra
  module SessionHelper
    def current_user
      @current_user ||= cookies[:_datacite].present? && ::JSON.parse(URI.decode(cookies[:_datacite])).to_h.dig("authenticated", "access_token") ? User.new(cookies[:_datacite]) : nil
    rescue JSON::ParserError
      nil
    end

    def user_signed_in?
      !!current_user
    end

    def is_person?
      current_user && current_user.is_person?
    end

    def is_beta_tester?
      current_user && current_user.beta_tester
    end

    def has_orcid_token?
      current_user && current_user.has_orcid_token
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end
  end

  helpers SessionHelper
end
