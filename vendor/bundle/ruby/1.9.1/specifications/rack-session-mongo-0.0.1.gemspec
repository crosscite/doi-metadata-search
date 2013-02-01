# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rack-session-mongo"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Masato Igarashi"]
  s.date = "2012-02-04"
  s.description = "Rack session store for MongoDB"
  s.email = ["m@igrs.jp"]
  s.homepage = "http://github.com/migrs/rack-session-mongo"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Rack session store for MongoDB"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_runtime_dependency(%q<rack>, [">= 0"])
      s.add_runtime_dependency(%q<mongo>, [">= 0"])
    else
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<mongo>, [">= 0"])
    end
  else
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<mongo>, [">= 0"])
  end
end
