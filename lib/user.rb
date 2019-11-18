require 'sinatra/base'
require 'jwt'
require 'sinatra/json'
require 'uri'

class User
  attr_accessor :name, :uid, :email, :jwt, :role_id, :role_name, :orcid, :provider_id, :client_id, :beta_tester, :has_orcid_token

  def initialize(cookie)
    token = ::JSON.parse(URI.decode(cookie)).to_h.dig("authenticated", "access_token")
    return false unless token.present?

    payload = decode_token(token)

    @jwt = token
    @uid = payload.fetch("uid", nil)
    @name = payload.fetch("name", nil)
    @email = payload.fetch("email", nil)
    @role_id = payload.fetch("role_id", nil)
    @provider_id = payload.fetch("provider_id", nil)
    @client_id = payload.fetch("client_id", nil)
    @beta_tester = payload.fetch("beta_tester", false)
    @has_orcid_token = payload.fetch("has_orcid_token", false)
  end

  alias_method :orcid, :uid

  # Helper method to check for admin user
  def is_admin?
    role_id == "staff_admin"
  end

  # Helper method to check for admin or staff user
  def is_admin_or_staff?
    ["staff_admin", "staff_user"].include?(role_id)
  end

  # Helper method to check for personal account
  def is_person?
    uid.start_with?("0")
  end

  def role_name
    if role_id == "user"
      "User"
    elsif role_id == "client_admin"
      "Client"
    elsif role_id == "provider_admin"
      "Member"
    elsif role_id == "staff_admin"
      "Staff"
    end
  end

  # encode token using SHA-256 hash algorithm
  def encode_token(payload)
    # replace newline characters with actual newlines
    private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
    JWT.encode(payload, private_key, 'RS256')
  end

  # decode token using SHA-256 hash algorithm
  def decode_token(token)
    public_key = OpenSSL::PKey::RSA.new(ENV['JWT_PUBLIC_KEY'].to_s.gsub('\n', "\n"))
    payload = (JWT.decode token, public_key, true, { :algorithm => 'RS256' }).first

    # check whether token has expired
    return {} unless Time.now.to_i < payload["exp"]

    payload
  rescue JWT::DecodeError => error
    { errors: "JWT::DecodeError: " + error.message + " for " + token }
  rescue OpenSSL::PKey::RSAError => error
    public_key = ENV['JWT_PUBLIC_KEY'].presence || "nil"
    { errors: "OpenSSL::PKey::RSAError: " + error.message + " for " + public_key }
  end

  # encode token using SHA-256 hash algorithm
  def self.encode_token(payload)
    # replace newline characters with actual newlines
    private_key = OpenSSL::PKey::RSA.new(ENV['JWT_PRIVATE_KEY'].to_s.gsub('\n', "\n"))
    JWT.encode(payload, private_key, 'RS256')
  end

  # generate JWT token
  def self.generate_token(attributes={})
    payload = {
      uid:  attributes.fetch(:uid, "0000-0001-5489-3594"),
      name: attributes.fetch(:name, "Josiah Carberry"),
      email: attributes.fetch(:email, nil),
      provider_id: attributes.fetch(:provider_id, nil),
      client_id: attributes.fetch(:client_id, nil),
      role_id: attributes.fetch(:role_id, "staff_admin"),
      iat: Time.now.to_i,
      exp: Time.now.to_i + attributes.fetch(:exp, 30)
    }.compact

    encode_token(payload)
  end

  def self.generate_cookie(attributes={})
    jwt = generate_token(attributes)

    expires_in = 30 * 24 * 3600
    expires_at = Time.now.to_i + expires_in
    value = '{"authenticated":{"authenticator":"authenticator:oauth2","access_token":"' + jwt + '","expires_in":' + expires_in.to_s + ',"expires_at":' + expires_at.to_s + '}}'
    
    domain = if ENV["RACK_ENV"] == "production"
               ".datacite.org"
             elsif ENV["RACK_ENV"] == "stage"
               ".test.datacite.org"
             else
               ".lvh.me"
             end
    
    # URI.encode optional parameter needed to encode colon
    URI.encode(value, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
