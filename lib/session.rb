module Sinatra
  module Session
    def current_user
      @current_user ||= session[:auth].present? ? User.new(session[:auth]) : nil
    end

    def current_user=(user)
      @current_user = user
      session[:auth] = user.nil? ? nil : user.auth_hash
    end

    def signed_in?
      !!current_user
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end

    def make_and_set_token(code, redirect)
      client = OAuth2::Client.new(ENV['ORCID_CLIENT_ID'],
                                  ENV['ORCID_CLIENT_SECRET'],
                                  site: ENV['ORCID_API_URL'])
      token_obj = client.auth_code.get_token(code, { redirect_uri: redirect })
      session[:auth] = {
        'credentials' => {
          'token' => token_obj.token
        },
        uid: token_obj.params['orcid'],
        info: {}
      }
    rescue OAuth2::Error => e
      { "errors" => e.inspect }
    end
  end

  helpers Session
end
