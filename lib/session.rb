# -*- coding: utf-8 -*-
module Session
  def update_claimed_publications
  end

  def signed_in?
    !session[:orcid].nil?
  end

  def user_display
    if signed_in?
      session[:orcid][:name] || session[:orcid][:uid]
    end
  end

  def after_signin_redirect
    redirect_to = session[:redirect] || '/'
    session.delete :redirect
    redirect_to
  end

  def set_after_signin_redirect redirect_to
    session[:redirect] = redirect_to
  end
end


