require 'sinatra/base'

class User
  attr_accessor :name, :uid, :email, :jwt, :role, :orcid, :member_id, :datacenter_id

  def initialize(jwt)
    return false unless jwt.present?

    # decode token using SHA-256 hash algorithm
    public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    payload = JWT.decode(jwt, public_key, true, { :algorithm => 'RS256' }).first

    # check whether token has expired
    return false unless Time.now.to_i < payload["exp"]

    @jwt = jwt
    @uid = payload.fetch("uid", nil)
    @name = payload.fetch("name", nil)
    @email = payload.fetch("email", nil)
    @role = payload.fetch("role", nil)
    @member_id = payload.fetch("member_id", nil)
    @datacenter_id = payload.fetch("datacenter_id", nil)
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
