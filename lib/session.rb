require 'json'

module Session
  def logger
    Log4r::Logger['test']
  end

  def auth_token
    OAuth2::AccessToken.new settings.orcid_oauth, session[:orcid]['credentials']['token']
  end

  def update_profile
    logger.debug "retrieving ORCID profile for #{session[:orcid][:uid]}"
    response = auth_token.get "/#{session[:orcid][:uid]}/orcid-profile", headers: { 'Accept' => 'application/json' }
    if response.status == 200
      json = JSON.parse(response.body)
      given_name = json['orcid-profile']['orcid-bio']['personal-details']['given-names']['value']
      family_name = json['orcid-profile']['orcid-bio']['personal-details']['family-name']['value']
      other_names = json['orcid-profile']['orcid-bio']['personal-details']['other-names'].nil? ? nil : json['orcid-profile']['orcid-bio']['personal-details']['other-names']['other-name']
      session[:orcid][:info][:name] = "#{given_name} #{family_name}"
      session[:orcid][:info][:other_names] = other_names.nil? ? nil : other_names.map { |other_name| other_name['value'] }
      logger.info 'Got updated profile data: ' + session[:orcid].ai
    end
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
      creds = session[:orcid]['credentials']
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
