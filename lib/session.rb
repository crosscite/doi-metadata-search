require 'json'

module Sinatra
  module Session
    def auth_token
      OAuth2::AccessToken.new(settings.orcid_oauth, session[:orcid]['credentials']['token'])
    end

    def signed_in?
      if session[:orcid].nil?
        false
      else
        !expired_session?
      end
    end

    # Returns true if there is a session and it has expired, or false if the
    # session has not expired or if there is no session.
    def expired_session?
      if session[:orcid].nil?
        false
      else
        creds = session.fetch(:orcid, {}).fetch('credentials', {})
        creds['expires'] && creds['expires_at'] <= Time.now.to_i
      end
    end

    def sign_in_id
      session[:orcid][:uid]
    end

    def user_display
      if signed_in?
        session[:orcid][:info][:name] || session[:orcid][:uid]
      end
    end

    def session_info
      session[:orcid]
    end
  end

  helpers Session
end
