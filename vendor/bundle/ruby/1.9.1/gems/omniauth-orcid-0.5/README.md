# OmniAuth ORCID

ORCID OAuth 2.0 Strategy for the wonderful [OmniAuth Ruby authentication framework](http://www.omniauth.org).

Provides basic support for connecting a client application to the [Open Researcher & Contributor ID registry service](http://about.orcid.org).

Originally created for the [ORCID example client application in Rails](https://github.com/gthorisson/ORCID-example-client-app-rails), then turned into a gem.



## Installation

The usual way with Bundler: add the following to your `Gemfile` to install the current version of the gem:

```ruby
gem 'omniauth-orcid'
```

Or, if you're impatient, you can install straight from GitHub

```ruby
gem 'omniauth-orcid' , :git => 'git://github.com/gthorisson/omniauth-orcid.git'
```

Then run `bundle install` to install into your environment.

You can also install the gem system-wide:

```bash
[mummi@nfmac07]gem install omniauth-orcid
```

## Getting started

Like other OmniAuth strategies, `OmniAuth::Strategies::ORCID` is a piece of Rack middleware. Please read the OmniAuth documentation for detailed instructions: https://github.com/intridea/omniauth.


By default the module connects to the live ORCID service. In the very simplest usage, all you have to provide are your client app credentials ([see more here](http://support.orcid.org/knowledgebase/articles/116739)):

```ruby
use OmniAuth::Builder do
  provider :orcid, ENV['ORCID_KEY'], ENV['ORCID_SECRET']
end
```

You also have to implement a callback handler to grab user data after the OAuth handshake has been completed, and then do something cool with those data. Here's how to get going with a couple of popular Rack-based frameworks:


### Sinatra


Configure the strategy and implement a callback routine in your app:

```ruby
require 'sinatra'
require 'sinatra/config_file'
require 'omniauth-orcid'
enable :sessions

use OmniAuth::Builder do
  provider :orcid, ENV['ORCID_KEY'], ENV['ORCID_SECRET']
end
...
get '/auth/orcid/callback' do
  session[:omniauth] = request.env['omniauth.auth']
  redirect '/'
end

get '/' do
  
  if session[:omniauth]
    @orcid = session[:omniauth][:uid]
  end
  ..
```

The bundled `demo.rb` file contains an uber-simple working Sinatra example app. Spin it up, point your browser to http://localhost:4567/ and play:

```bash
gem install sinatra
ruby demo.rb
[2012-11-26 21:41:08] INFO  WEBrick 1.3.1
[2012-11-26 21:41:08] INFO  ruby 1.9.3 (2012-04-20) [x86_64-darwin11.3.0]
== Sinatra/1.3.2 has taken the stage on 4567 for development with backup from WEBrick
[2012-11-26 21:41:08] INFO  WEBrick::HTTPServer#start: pid=8383 port=4567

```


### Rails 


Add this to `config/initializers/omniauth.rb` to configure the strategy:

```ruby
require 'omniauth-orcid'

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :orcid, ENV['ORCID_KEY'], ENV['ORCID_SECRET']
end
```

Register a callback path in 'config/routes.rb'

```ruby
..
  match '/auth/:provider/callback' => 'authentications#create'
..
```

Implement a callback handler method in a controller:

```ruby
class AuthenticationsController < ApplicationController
  ..
  def create
    omniauth = request.env["omniauth.auth"]
    session[:omniauth] = omniauth
    session[:params]   = params
    ..
  end
```



## Configuration

You can also grab parameters from a config file (recommended) and pass to the strategy via the `:client_options` hash. Here's an example from the bundled Sinatra app in `demo.rb`:

```ruby
config_file 'config.yml'
use OmniAuth::Builder do
  provider :orcid, settings.client_id, settings.client_secret, 
  :client_options => {
    :site => settings.site, 
    :authorize_url => settings.authorize_url,
    :token_url => settings.token_url
  }
end

```

Different sets of params from `config.yml` are used for production environment (points to live ORCID service) vs. development environment (points to ORCID sandbox service).

You can d something similar with in Rails with the same config file, or something . See a working example here: https://github.com/gthorisson/ORCID-example-client-app-rails



## More information 

ORCID Developer Portal - http://dev.orcid.org




## License

The MIT License (OSI approved, see more at http://www.opensource.org/licenses/mit-license.php)

=============================================================================

Copyright (C) 2012 by Gudmundur A. Thorisson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=============================================================================

![Open Source Initiative Approved License](http://www.opensource.org/trademarks/opensource/web/opensource-110x95.jpg)
