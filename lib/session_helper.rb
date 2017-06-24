require 'sinatra/base'

module Sinatra
  module SessionHelper
    # replace newline characters with actual newlines
    def public_key
      OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    end

    def current_user
      @current_user ||= cookies[:_datacite_jwt].present? ? User.new((JWT.decode cookies[:_datacite_jwt], public_key, true, { :algorithm => 'RS256' }).first) : nil
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
