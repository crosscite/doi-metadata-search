# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rsolr"
  s.version = "1.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Antoine Latter", "Dmitry Lihachev", "Lucas Souza", "Peter Kieltyka", "Rob Di Marco", "Magnus Bergmark", "Jonathan Rochkind", "Chris Beer", "Craig Smith", "Randy Souza", "Colin Steele", "Peter Kieltyka", "Lorenzo Riccucci", "Mike Perham", "Mat Brown", "Shairon Toledo", "Matthew Rudy", "Fouad Mardini", "Jeremy Hinegardner", "Nathan Witmer", "\"shima\""]
  s.date = "2012-04-22"
  s.description = "RSolr aims to provide a simple and extensible library for working with Solr"
  s.email = ["goodieboy@gmail.com"]
  s.homepage = "https://github.com/mwmitchell/rsolr"
  s.require_paths = ["lib"]
  s.rubyforge_project = "rsolr"
  s.rubygems_version = "1.8.23"
  s.summary = "A Ruby client for Apache Solr"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<builder>, [">= 2.1.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 3.9.4"])
      s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
    else
      s.add_dependency(%q<builder>, [">= 2.1.2"])
      s.add_dependency(%q<rake>, ["~> 0.9.2"])
      s.add_dependency(%q<rdoc>, ["~> 3.9.4"])
      s.add_dependency(%q<rspec>, ["~> 2.6.0"])
    end
  else
    s.add_dependency(%q<builder>, [">= 2.1.2"])
    s.add_dependency(%q<rake>, ["~> 0.9.2"])
    s.add_dependency(%q<rdoc>, ["~> 3.9.4"])
    s.add_dependency(%q<rspec>, ["~> 2.6.0"])
  end
end
