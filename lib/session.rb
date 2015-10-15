require 'json'

module Sinatra
  module Session
    def auth_token
      OAuth2::AccessToken.new(Sinatra::Application.settings.orcid_oauth, session_info['credentials']['token'])
    end

    def make_and_set_token(code, redirect)
      client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                  ENV['ORCID_CLIENT_SECRET'],
                                  site: ENV['ORCID_API_URL'])
      token_obj = client.auth_code.get_token(code, { redirect_uri: redirect })
      session[:orcid] = {
        'credentials' => {
          'token' => token_obj.token
        },
        :uid => token_obj.params['orcid'],
        :info => {}
      }
    rescue OAuth2::Error => e
      { error: e.inspect }
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
