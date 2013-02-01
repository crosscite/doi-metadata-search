# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "omniauth-orcid"
  s.version = "0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gudmundur A. Thorisson"]
  s.date = "2012-11-28"
  s.description = "Enables third-party client apps to connect to the ORCID API and access/update protected profile data "
  s.email = "gthorisson@gmail.com"
  s.extra_rdoc_files = ["README.md"]
  s.files = ["README.md"]
  s.homepage = "https://github.com/gthorisson/omniauth-orcid"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "ORCID OAuth 2.0 Strategy for OmniAuth 1.0"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<omniauth>, ["~> 1.0"])
      s.add_runtime_dependency(%q<omniauth-oauth2>, ["~> 1.1"])
    else
      s.add_dependency(%q<omniauth>, ["~> 1.0"])
      s.add_dependency(%q<omniauth-oauth2>, ["~> 1.1"])
    end
  else
    s.add_dependency(%q<omniauth>, ["~> 1.0"])
    s.add_dependency(%q<omniauth-oauth2>, ["~> 1.1"])
  end
end
