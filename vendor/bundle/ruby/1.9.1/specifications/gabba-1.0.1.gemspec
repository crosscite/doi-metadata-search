# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "gabba"
  s.version = "1.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ron Evans"]
  s.date = "2012-11-08"
  s.description = "Easy server-side tracking for Google Analytics"
  s.email = ["ron dot evans at gmail dot com"]
  s.homepage = "https://github.com/hybridgroup/gabba"
  s.require_paths = ["lib"]
  s.rubyforge_project = "gabba"
  s.rubygems_version = "1.8.23"
  s.summary = "Easy server-side tracking for Google Analytics"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
