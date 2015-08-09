firewall Cookbook
=================
[![Build Status](https://secure.travis-ci.org/opscode-cookbooks/firewall.png?branch=master)](http://travis-ci.org/opscode-cookbooks/firewall)

Provides a set of primitives for managing firewalls and associated rules.

PLEASE NOTE - The resource/providers in this cookbook are under heavy development. An attempt is being made to keep the resource simple/stupid by starting with less sophisticated firewall implementations first and refactor/vet the resource definition with each successive provider.


Requirements
------------
### Platform
* Ubuntu
* Debian
* Redhat
* CentOS

Tested on:
* Ubuntu 12.04
* Ubuntu 14.04
* Debian 7.8
* CentOS 5.11
* CentOS 6.5
* CentOS 7.0


Recipes
-------
### default
The default recipe creates a firewall resource with action install, and if `node['firewall']['allow_ssh']`, opens port 22 from the world.


Attributes
----------

* `default['firewall']['ufw']['defaults']` hash for template `/etc/default/ufw`

Resources/Providers
-------------------
- See `librariez/z_provider_mapping.rb` for a full list of providers for each platform and version.

### firewall
#### Actions
- `:enable`: *Default action* enable the firewall.  this will make any rules that have been defined 'active'.
- `:disable`: disable the firewall. drop any rules and put the node in an unprotected state.
- `:flush`: Runs `iptables -F`. Only supported by the iptables firewall provider.
- `:save`: Runs `service iptables save` under iptables, adds rules permanently under firewall. Not supported in ufw.

#### Attribute Parameters
- name: name attribute. arbitrary name to uniquely identify this resource
- log_level: level of verbosity the firewall should log at. valid values are: :low, :medium, :high, :full. default is :low.

#### Examples

```ruby
# enable platform default firewall
firewall 'ufw' do
  action :enable
end

# increase logging past default of 'low'
firewall 'debug firewalls' do
  log_level :high
  action    :enable
end
```

### firewall_rule

#### Actions
- `:allow`: the rule should allow incoming traffic.
- `:deny`: the rule should deny incoming traffic.
- `:reject`: *Default action: the rule should reject incoming traffic.
- `:masqerade`: Add masqerade rule
- `:redirect`: Add redirect-type rule
- `:log`: Configure logging
- `:remove`: Remove all rules

#### Attribute Parameters
- name: name attribute. arbitrary name to uniquely identify this firewall rule
- protocol: valid values are: :icmp, :udp, :tcp, or protocol number. default is :tcp. Using protocol numbers is not supported using the ufw provider (default for debian/ubuntu systems).
- port: incoming port number (ie. 22 to allow inbound SSH), or an array of incoming port numbers (ie. [80,443] to allow inbound HTTP & HTTPS). NOTE: `protocol` attribute is required with multiple ports, or a range of incoming port numbers (ie. 60000..61000 to allow inbound mobile-shell. NOTE: `protocol`, or an attribute is required with a range of ports.
- source: ip address or subnet to filter on incoming traffic. default is `0.0.0.0/0` (ie Anywhere)
- destination: ip address or subnet to filter on outgoing traffic.
- dest_port: outgoing port number.
- position: position to insert rule at. if not provided rule is inserted at the end of the rule list.
- direction: direction of the rule. valid values are: :in, :out, default is :in
- interface: interface to apply rule (ie. 'eth0').
- logging: may be added to enable logging for a particular rule. valid values are: :connections, :packets. In the ufw provider, :connections logs new connections while :packets logs all packets.
- raw: for passing a raw command to the provider (for use with custom modules, also used by zap provider to clean up non-chef managed rules)

#### Examples

```ruby
# open standard ssh port, enable firewall
firewall_rule 'ssh' do
  port     22
  action   :allow
  notifies :enable, 'firewall[ufw]'
end

# open standard http port to tcp traffic only; insert as first rule
firewall_rule 'http' do
  port     80
  protocol :tcp
  position 1
  action   :allow
end

# restrict port 13579 to 10.0.111.0/24 on eth0
firewall_rule 'myapplication' do
  port      13579
  source    '10.0.111.0/24'
  direction :in
  interface 'eth0'
  action    :allow
end

# specify a protocol number (supported on centos/redhat)
firewall_rule 'vrrp' do
  protocol    112
  action      :allow
end

# use the iptables provider to specify protocol number on debian/ubuntu
firewall_rule 'vrrp' do
  provider    Chef::Provider::FirewallRuleIptables
  protocol    112
  action      :allow
end

# open UDP ports 60000..61000 for mobile shell (mosh.mit.edu), note
# that the protocol attribute is required when using port_range
firewall_rule 'mosh' do
  protocol   :udp
  port       60000..61000
  action     :allow
end

# open multiple ports for http/https, note that the protocol
# attribute is required when using ports
firewall_rule 'http/https' do
  protocol :tcp
  port     [80, 443]
  action   :allow
end

firewall 'ufw' do
  action :nothing
end
```


Development
-----------
This section details "quick development" steps. For a detailed explanation, see [[Contributing.md]].

1. Clone this repository from GitHub:

        $ git clone git@github.com:opscode-cookbooks/firewall.git

2. Create a git branch

        $ git checkout -b my_bug_fix

3. Install dependencies:

        $ bundle install

4. Make your changes/patches/fixes, committing appropiately
5. **Write tests**
6. Run the tests:
    - `bundle exec foodcritic -f any .`
    - `bundle exec rspec`
    - `bundle exec rubocop`
    - `bundle exec kitchen test`

  In detail:
    - Foodcritic will catch any Chef-specific style errors
    - RSpec will run the unit tests
    - Rubocop will check for Ruby-specific style errors
    - Test Kitchen will run and converge the recipes


License & Authors
-----------------
- Author:: Seth Chisamore (<schisamo@opscode.com>)

```text
Copyright:: Copyright (c) 2011-2015 Opscode, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
