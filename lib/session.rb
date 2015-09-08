require 'json'

module Sinatra
  module Session
    def auth_token
      OAuth2::AccessToken.new(Sinatra::Application.settings.orcid_oauth, session_info['credentials']['token'])
    end

    def signed_in?
      if session_info.nil?
        false
      else
        !expired_session?
      end
    end

    # Returns true if there is a session and it has expired, or false if the
    # session has not expired or if there is no session.
    def expired_session?
      if session_info.nil?
        false
      else
        creds = session_info['credentials']
        creds['expires'] && creds['expires_at'] <= Time.now.to_i
      end
    end

    def sign_in_id
      session_info[:uid]
    end

    def user_display
      if signed_in?
        session_info[:info][:name] || session_info[:uid]
      end
    end

    def session_info
      defined?(session) ? session[:orcid] : { "credentials" => {} }
    end
  end

  helpers Session
end
