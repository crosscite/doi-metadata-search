# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "omniauth"
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Bleigh", "Erik Michaels-Ober"]
  s.date = "2012-08-24"
  s.description = "A generalized Rack framework for multiple-provider authentication."
  s.email = ["michael@intridea.com", "sferik@gmail.com"]
  s.homepage = "http://github.com/intridea/omniauth"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "A generalized Rack framework for multiple-provider authentication."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<hashie>, ["~> 1.2"])
      s.add_development_dependency(%q<maruku>, [">= 0"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8"])
      s.add_development_dependency(%q<yard>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<hashie>, ["~> 1.2"])
      s.add_dependency(%q<maruku>, [">= 0"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.8"])
      s.add_dependency(%q<yard>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<hashie>, ["~> 1.2"])
    s.add_dependency(%q<maruku>, [">= 0"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.8"])
    s.add_dependency(%q<yard>, [">= 0"])
  end
end
