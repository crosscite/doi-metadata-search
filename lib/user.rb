require 'sinatra/base'

class User
  attr_accessor :name, :uid, :role, :api_key, :expires_at, :orcid

  def initialize(auth_hash={})
    @uid = auth_hash.fetch("uid", nil)

    info = auth_hash.fetch("info", {})
    @name = info.fetch("name", nil)
    @role = info.fetch("role", nil)
    @expires_at = info.fetch("expires_at", nil)
    @api_key = info.fetch("api_key", nil)
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
