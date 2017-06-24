require 'sinatra/base'

module Sinatra
  module SessionHelper
    def current_user
      @current_user ||= cookies[:_datacite_jwt].present? ? User.new(cookies[:_datacite_jwt]) : nil
    end

    def user_signed_in?
      !!current_user
    end

    def is_admin_or_staff?
      current_user && current_user.is_admin_or_staff?
    end
  end

  helpers SessionHelper
end
