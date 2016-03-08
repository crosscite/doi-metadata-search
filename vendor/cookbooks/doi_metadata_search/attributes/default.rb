default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
default['ruby']['rails_env'] = "development"
default['ruby']['merge_slashes_off'] = true
default['ruby']['enable_capistrano'] = false

default['ruby']['packages'] = %w{ curl git mysql-client-core-5.5 libmysqlclient-dev python-software-properties software-properties-common zlib1g-dev }
default['ruby']['packages'] += %w{ avahi-daemon libnss-mdns } if node['ruby']['rails_env'] != "production"

default["application"] = "doi-metadata-search"

default['nodejs']['repo'] = 'https://deb.nodesource.com/node_0.12'
default['nodejs']['npm_packages'] = [{ "name" => "phantomjs" },
                                     { "name" => "istanbul"},
                                     { "name" => "codeclimate-test-reporter" }]
