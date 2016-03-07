require 'sinatra/base'

module Sinatra
  module SessionHelper
    def current_user
      @current_user ||= session[:auth].present? ? User.new(session[:auth]) : nil
    end

    def signed_in?
      !!current_user
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end
  end

  helpers SessionHelper
end
