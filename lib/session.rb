require 'json'

module Session
  def auth_token
    OAuth2::AccessToken.new settings.orcid_oauth, session[:orcid]['credentials']['token']
  end

  def update_profile
    response = auth_token.get "#{session[:orcid][:uid]}/orcid-profile", :headers => {'Accept' => 'application/json'}
    if response.status == 200
      json = JSON.parse(response.body)
      given_name = json['orcid-profile']['orcid-bio']['personal-details']['given-names']['value']
      family_name = json['orcid-profile']['orcid-bio']['personal-details']['family-name']['value']
      session[:orcid][:info][:name] = "#{given_name} #{family_name}"
    end
  end

  def signed_in?
    if session[:orcid].nil?
      false
    else
      !(session[:orcid]['expires'] && session[:orcid]['expires_at'] <= Time.now.to_i)
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

  def after_signin_redirect
    redirect_to = session[:after_signin_redirect] || '/'
    session.delete :after_signin_redirect
    redirect_to
  end

  def set_after_signin_redirect redirect_to
    session[:after_signin_redirect] = redirect_to
  end
end


