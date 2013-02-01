# ORCID example client application in Sinatra.
# Modelled after this app: https://github.com/zuzara/jQuery-OAuth-Popup

require 'rubygems'
require 'sinatra'
require 'sinatra/config_file'
require 'haml'
require 'omniauth-orcid'
require 'json'

enable :sessions
use Rack::Session::Cookie

config_file 'config.yml'
if development?
  puts "Sinatra running in development mode"
elsif production?
  puts "Sinatra running in production mode"  
end

puts "Connecting to ORCID API at " + settings.site + " as client app #{settings.client_id}"

# Configure the ORCID strategy
use OmniAuth::Builder do
  provider :orcid, settings.client_id, settings.client_secret, 
  :client_options => {
    :site => settings.site, 
    :authorize_url => settings.authorize_url,
    :token_url => settings.token_url
  }
end


get '/' do

  @orcid = ''
  
  if session[:omniauth]
    @orcid = session[:omniauth][:uid]
  end
  haml <<-HTML
%html
  %head
    %title ORCID OmniAuth demo app
  %body
    - if session[:omniauth]
      %p
        Signed in with ORCiD <b>#{@orcid}</b>
      %p
        %a(href="/user_info")fetch user info as JSON
      %p
        %a(href="/signout") sign out 
    - else
      %p
        %a(href="/auth/orcid") Log in with my ORCiD
  HTML
end


get '/user_info' do
  content_type :json
  session[:omniauth].to_json
end


get '/auth/orcid/callback' do
  puts "Adding OmniAuth user info to session: " +  request.env['omniauth.auth'].inspect
  session[:omniauth] = request.env['omniauth.auth']
  redirect '/'
end

get '/signout' do
  session.clear
  redirect '/'
end


__END__
