default['ruby']['deploy_user'] = "vagrant"
default['ruby']['deploy_group'] = "vagrant"
default['ruby']['rails_env'] = "development"
default['ruby']['packages'] = %w{ curl git python-software-properties software-properties-common zlib1g-dev }
default['ruby']['packages'] += %w{ avahi-daemon libnss-mdns } if node['ruby']['rails_env'] != "production"
default["dotenv"] = "default"
default["application"] = "doi-metadata-search"
default['ruby']['merge_slashes_off'] = true
default['ruby']['api_only'] = false
