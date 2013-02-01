# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "httpauth"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Manfred Stienstra"]
  s.date = "2012-09-25"
  s.description = "Library for the HTTP Authentication protocol (RFC 2617)"
  s.email = "manfred@fngtpspec.com"
  s.extra_rdoc_files = ["README.md", "LICENSE"]
  s.files = ["README.md", "LICENSE"]
  s.homepage = "https://github.com/Manfred/HTTPauth"
  s.rdoc_options = ["--charset=utf-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "HTTPauth is a library supporting the full HTTP Authentication protocol as specified in RFC 2617; both Digest Authentication and Basic Authentication."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
