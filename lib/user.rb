require 'sinatra/base'

class User
  attr_accessor :name, :uid, :email, :jwt, :role, :orcid

  def initialize(jwt)
    public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    jwt_hsh = JWT.decode(jwt, public_key, true, { :algorithm => 'RS256' }).first

    @jwt = jwt
    @uid = jwt_hsh.fetch("uid", nil)
    @name = jwt_hsh.fetch("name", nil)
    @email = jwt_hsh.fetch("email", nil)
    @role = jwt_hsh.fetch("role", nil)
  end

  alias_method :orcid, :uid

  # Helper method to check for admin user
  def is_admin?
    role == "admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["admin", "staff"].include?(role)
  end
end
